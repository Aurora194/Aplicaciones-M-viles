import {
  PrismaClient,
  EstadoReserva,
  Rol,
} from "@prisma/client";

const prisma =
  new PrismaClient();

export class ReservaService {
  async getReservas(
    page: number,
    limit: number,
    cliente?: string,
    mesa?: number,
    fecha?: string,
    estado?: EstadoReserva,
    order: "asc" | "desc" = "asc",
    actor?: {
      id: number;
      rol: Rol;
    }
  ) {
    const safePage =
      Math.max(1, page);

    const safeLimit =
      Math.max(
        1,
        Math.min(limit, 100)
      );

    const skip =
      (safePage - 1) *
      safeLimit;

    const where: any = {
      deletedAt: null,
    };

    if (
      actor?.rol !== Rol.ADMIN
    ) {
      where.usuarioId =
        actor?.id;
    }

    if (cliente) {
      where.usuario = {
        OR: [
          {
            nombre: {
              contains: cliente,
            },
          },
          {
            apellido: {
              contains: cliente,
            },
          },
          {
            correo: {
              contains: cliente,
            },
          },
        ],
      };
    }

    if (mesa) {
      where.mesaId = mesa;
    }

    if (fecha) {
      const inicio =
        new Date(fecha);

      const fin =
        new Date(fecha);

      fin.setDate(
        fin.getDate() + 1
      );

      where.fecha = {
        gte: inicio,
        lt: fin,
      };
    }

    if (estado) {
      where.estado = estado;
    }

    const total =
      await prisma.reserva.count({
        where,
      });

    const reservas =
      await prisma.reserva.findMany({
        where,
        include: {
          usuario: {
            select: {
              id: true,
              nombre: true,
              apellido: true,
              correo: true,
            },
          },
          mesa: {
            select: {
              id: true,
              numero: true,
              capacidad: true,
            },
          },
        },
        skip,
        take: safeLimit,
        orderBy: {
          fecha: order,
        },
      });

    return {
      success: true,
      message: "Lista de reservas",
      data: reservas,
      pagination: {
        page: safePage,
        limit: safeLimit,
        total,
        totalPages:
          Math.ceil(
            total / safeLimit
          ),
      },
    };
  }

  async getOne(
    id: number,
    actor?: {
      id: number;
      rol: Rol;
    }
  ) {
    const reserva =
      await prisma.reserva.findFirst({
        where: {
          id,
          deletedAt: null,
          ...(actor?.rol === Rol.ADMIN
            ? {}
            : {
                usuarioId:
                  actor?.id,
              }),
        },
        include: {
          usuario: true,
          mesa: true,
        },
      });

    if (!reserva) {
      throw new Error(
        "Reserva no encontrada"
      );
    }

    return {
      success: true,
      data: reserva,
    };
  }

  async create(
    data: any,
    actor?: {
      id: number;
      rol: Rol;
    }
  ) {
    const usuarioId =
      actor?.rol === Rol.CLIENTE
        ? actor.id
        : Number(data.usuarioId);

    const fecha =
      new Date(data.fecha);

    const mesaId =
      Number(data.mesaId);

    const personas =
      Number(data.personas);

    if (
      !usuarioId ||
      Number.isNaN(
        fecha.getTime()
      ) ||
      !mesaId ||
      !Number.isInteger(
        personas
      ) ||
      personas < 1
    ) {
      throw new Error(
        "Datos de reserva inválidos"
      );
    }

    const usuario =
      await prisma.usuario.findUnique(
        {
          where: {
            id: usuarioId,
          },
        }
      );

    if (!usuario) {
      throw new Error(
        "Usuario no existe"
      );
    }

    const mesa =
      await prisma.mesa.findUnique(
        {
          where: {
            id: mesaId,
          },
        }
      );

    if (!mesa) {
      throw new Error(
        "Mesa no existe"
      );
    }

    if (
      mesa.deletedAt != null
    ) {
      throw new Error(
        "La mesa no está disponible"
      );
    }

    if (!mesa.disponible) {
      throw new Error(
        "La mesa está marcada como no disponible"
      );
    }

    if (
      personas > mesa.capacidad
    ) {
      throw new Error(
        "La cantidad de personas excede la capacidad de la mesa"
      );
    }

    const reserva =
      await prisma.$transaction(
        async (tx) => {
          const existente =
            await tx.reserva.findFirst(
              {
                where: {
                  mesaId,
                  fecha,
                  estado: {
                    in: [
                      EstadoReserva.PENDIENTE,
                      EstadoReserva.CONFIRMADA,
                    ],
                  },
                  deletedAt: null,
                },
              }
            );

          if (existente) {
            throw new Error(
              "La mesa ya está reservada para esa fecha y hora"
            );
          }

          return tx.reserva.create({
            data: {
              fecha,
              personas,
              estado:
                EstadoReserva.PENDIENTE,
              usuarioId,
              mesaId,
            },
            include: {
              usuario: true,
              mesa: true,
            },
          });
        }
      );

    await prisma.notificacion.create({
      data: {
        usuarioId,
        mensaje:
          `Reserva #${reserva.id} creada y pendiente de confirmación.`,
      },
    });

    return {
      success: true,
      message:
        "Reserva creada correctamente",
      data: reserva,
    };
  }

  async update(
    id: number,
    data: any,
    actor?: {
      id: number;
      rol: Rol;
    }
  ) {
    const existe =
      await prisma.reserva.findFirst({
        where: {
          id,
          deletedAt: null,
          ...(actor?.rol === Rol.ADMIN
            ? {}
            : {
                usuarioId:
                  actor?.id,
              }),
        },
      });

    if (!existe) {
      throw new Error(
        "Reserva no encontrada"
      );
    }

    const fecha =
      data.fecha
        ? new Date(data.fecha)
        : existe.fecha;

    const mesaId =
      data.mesaId != null
        ? Number(data.mesaId)
        : existe.mesaId;

    const personas =
      data.personas != null
        ? Number(data.personas)
        : existe.personas;

    const estado =
      data.estado ??
      existe.estado;

    if (
      Number.isNaN(
        fecha.getTime()
      )
    ) {
      throw new Error(
        "Fecha de reserva inválida"
      );
    }

    if (
      actor?.rol === Rol.CLIENTE &&
      estado !== existe.estado &&
      estado !==
        EstadoReserva.CANCELADA
    ) {
      throw new Error(
        "El cliente solo puede cancelar su reserva"
      );
    }

    if (
      actor?.rol !== Rol.ADMIN &&
      estado ===
        EstadoReserva.CONFIRMADA
    ) {
      throw new Error(
        "Solo un administrador puede confirmar reservas"
      );
    }

    if (
      existe.estado ===
        EstadoReserva.CANCELADA &&
      estado !==
        EstadoReserva.CANCELADA
    ) {
      throw new Error(
        "Una reserva cancelada no puede reactivarse"
      );
    }

    const mesa =
      await prisma.mesa.findUnique({
        where: {
          id: mesaId,
        },
      });

    if (!mesa) {
      throw new Error(
        "Mesa no existe"
      );
    }

    if (
      mesa.deletedAt != null
    ) {
      throw new Error(
        "La mesa no está disponible"
      );
    }

    if (
      !mesa.disponible &&
      estado !==
        EstadoReserva.CANCELADA
    ) {
      throw new Error(
        "La mesa está marcada como no disponible"
      );
    }

    if (
      personas > mesa.capacidad
    ) {
      throw new Error(
        "La cantidad de personas excede la capacidad de la mesa"
      );
    }

    if (
      estado !==
        EstadoReserva.CANCELADA
    ) {
      const conflicto =
        await prisma.reserva.findFirst(
          {
            where: {
              id: {
                not: id,
              },
              mesaId,
              fecha,
              estado: {
                in: [
                  EstadoReserva.PENDIENTE,
                  EstadoReserva.CONFIRMADA,
                ],
              },
              deletedAt: null,
            },
          }
        );

      if (conflicto) {
        throw new Error(
          "La mesa ya está reservada para esa fecha y hora"
        );
      }
    }

    const reserva =
      await prisma.reserva.update(
        {
          where: {
            id,
          },
          data: {
            fecha,
            personas,
            mesaId,
            usuarioId:
              actor?.rol === Rol.CLIENTE
                ? actor.id
                : (
                    data.usuarioId ??
                    existe.usuarioId
                  ),
            estado,
          },
          include: {
            usuario: true,
            mesa: true,
          },
        }
      );

    if (
      estado !==
      existe.estado
    ) {
      await prisma.notificacion.create({
        data: {
          usuarioId:
            reserva.usuarioId,
          mensaje:
            `La reserva #${reserva.id} cambió a estado ${estado}.`,
        },
      });
    }

    return {
      success: true,
      message:
        "Reserva actualizada",
      data: reserva,
    };
  }

  async remove(
    id: number,
    actor?: {
      id: number;
      rol: Rol;
    }
  ) {
    const reserva =
      await prisma.reserva.findFirst({
        where: {
          id,
          deletedAt: null,
          ...(actor?.rol === Rol.ADMIN
            ? {}
            : {
                usuarioId:
                  actor?.id,
              }),
        },
      });

    if (!reserva) {
      throw new Error(
        "Reserva no encontrada"
      );
    }

    const reservaCancelada =
      await prisma.reserva.update(
        {
          where: {
            id,
          },
          data: {
            estado:
              EstadoReserva.CANCELADA,
          },
        }
      );

    return {
      success: true,
      message:
        "Reserva cancelada correctamente",
      data: reservaCancelada,
    };
  }
}