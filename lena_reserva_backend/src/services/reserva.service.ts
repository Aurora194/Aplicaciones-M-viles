import {
  PrismaClient,
  EstadoReserva,
  Rol,
} from "@prisma/client";

const prisma = new PrismaClient();

export class ReservaService {
  /* ============================================================
     LISTAR RESERVAS
     ============================================================ */

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
    const safePage = Math.max(1, page);

    const safeLimit = Math.max(
      1,
      Math.min(limit, 100)
    );

    const skip = (safePage - 1) * safeLimit;

    /*
     * IMPORTANTE:
     *
     * deletedAt: null hace que las reservas
     * eliminadas no vuelvan a aparecer.
     */
    const where: any = {
      deletedAt: null,
    };

    /*
     * Los clientes solamente pueden
     * consultar sus propias reservas.
     *
     * El administrador puede consultar
     * todas las reservas.
     */
    if (actor?.rol !== Rol.ADMIN) {
      where.usuarioId = actor?.id;
    }

    /* FILTRO POR CLIENTE */
    if (cliente && cliente.trim().length > 0) {
      where.usuario = {
        OR: [
          {
            nombre: {
              contains: cliente.trim(),
            },
          },
          {
            apellido: {
              contains: cliente.trim(),
            },
          },
          {
            correo: {
              contains: cliente.trim(),
            },
          },
        ],
      };
    }

    /* FILTRO POR MESA */
    if (mesa) {
      where.mesaId = mesa;
    }

    /* FILTRO POR FECHA */
    if (fecha) {
      const inicio = new Date(fecha);

      if (!Number.isNaN(inicio.getTime())) {
        const fin = new Date(inicio);

        fin.setDate(fin.getDate() + 1);

        where.fecha = {
          gte: inicio,
          lt: fin,
        };
      }
    }

    /* FILTRO POR ESTADO */
    if (estado) {
      where.estado = estado;
    }

    /*
     * Contamos solamente las reservas
     * activas.
     */
    const total = await prisma.reserva.count({
      where,
    });

    /*
     * IMPORTANTE:
     *
     * Ordenamos primero por fecha.
     * Como segundo criterio usamos ID
     * para que dos reservas con la misma
     * fecha/hora mantengan un orden estable.
     */
    const reservas = await prisma.reserva.findMany({
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

      orderBy: [
        {
          fecha: order,
        },
        {
          id: order,
        },
      ],
    });

    return {
      success: true,
      message: "Lista de reservas",

      data: reservas,

      pagination: {
        page: safePage,
        limit: safeLimit,
        total,

        totalPages: Math.ceil(
          total / safeLimit
        ),

        hasNextPage:
          safePage <
          Math.ceil(total / safeLimit),

        hasPreviousPage:
          safePage > 1,
      },
    };
  }

  /* ============================================================
     OBTENER UNA RESERVA
     ============================================================ */

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

          /*
           * Una reserva eliminada
           * ya no puede consultarse.
           */
          deletedAt: null,

          ...(actor?.rol === Rol.ADMIN
            ? {}
            : {
                usuarioId: actor?.id,
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

  /* ============================================================
     CREAR RESERVA
     ============================================================ */

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

    const fecha = new Date(data.fecha);

    const mesaId = Number(data.mesaId);

    const personas = Number(data.personas);

    if (
      !usuarioId ||
      Number.isNaN(fecha.getTime()) ||
      !mesaId ||
      !Number.isInteger(personas) ||
      personas < 1
    ) {
      throw new Error(
        "Datos de reserva inválidos"
      );
    }

    const usuario =
      await prisma.usuario.findUnique({
        where: {
          id: usuarioId,
        },
      });

    if (!usuario) {
      throw new Error(
        "Usuario no existe"
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

    if (mesa.deletedAt != null) {
      throw new Error(
        "La mesa no está disponible"
      );
    }

    if (!mesa.disponible) {
      throw new Error(
        "La mesa está marcada como no disponible"
      );
    }

    if (personas > mesa.capacidad) {
      throw new Error(
        "La cantidad de personas excede la capacidad de la mesa"
      );
    }

    /*
     * Verificamos que no exista otra
     * reserva activa para la misma mesa,
     * fecha y hora.
     */
    const reserva =
      await prisma.$transaction(
        async (tx) => {
          const existente =
            await tx.reserva.findFirst({
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
            });

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

    /*
     * Notificación.
     */
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

  /* ============================================================
     ACTUALIZAR RESERVA
     ============================================================ */

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

    if (mesa.deletedAt != null) {
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

    if (personas > mesa.capacidad) {
      throw new Error(
        "La cantidad de personas excede la capacidad de la mesa"
      );
    }

    /*
     * Verificar conflicto.
     */
    if (
      estado !==
      EstadoReserva.CANCELADA
    ) {
      const conflicto =
        await prisma.reserva.findFirst({
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
        });

      if (conflicto) {
        throw new Error(
          "La mesa ya está reservada para esa fecha y hora"
        );
      }
    }

    const reserva =
      await prisma.reserva.update({
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
      });

    /*
     * Notificación cuando cambia el estado.
     */
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

  /* ============================================================
     ELIMINAR RESERVA
     ============================================================ */

  async remove(
    id: number,
    actor?: {
      id: number;
      rol: Rol;
    }
  ) {
    /*
     * Solamente ADMIN puede eliminar.
     */
    if (actor?.rol !== Rol.ADMIN) {
      throw new Error(
        "Solo un administrador puede eliminar reservas"
      );
    }

    /*
     * Buscar solamente reservas
     * que todavía no estén eliminadas.
     */
    const reserva =
      await prisma.reserva.findFirst({
        where: {
          id,
          deletedAt: null,
        },
      });

    if (!reserva) {
      throw new Error(
        "Reserva no encontrada"
      );
    }

    /*
     * BORRADO LÓGICO.
     *
     * No borramos físicamente el registro.
     * Simplemente colocamos la fecha
     * de eliminación.
     */
    const reservaEliminada =
      await prisma.reserva.update({
        where: {
          id,
        },

        data: {
          deletedAt: new Date(),
        },

        include: {
          usuario: true,
          mesa: true,
        },
      });

    return {
      success: true,

      message:
        "Reserva eliminada correctamente",

      data: reservaEliminada,
    };
  }
}

