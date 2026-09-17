import {
  EstadoReserva,
  PrismaClient,
} from "@prisma/client";

const prisma = new PrismaClient();

export class MesaService {
  // =========================================================
  // LISTAR MESAS
  // =========================================================

  async getMesas(
    page: number,
    limit: number,
    search?: string,
    disponible?: boolean,
    order: "asc" | "desc" = "asc"
  ) {
    const safePage = Math.max(1, page);

    const safeLimit = Math.max(
      1,
      Math.min(limit, 100)
    );

    const skip =
      (safePage - 1) * safeLimit;

    const where: any = {
      deletedAt: null,
    };

    if (search && search.trim()) {
      where.numero = {
        contains: search.trim(),
      };
    }

    if (disponible !== undefined) {
      where.disponible = disponible;
    }

    const total =
      await prisma.mesa.count({
        where,
      });

    const mesas =
      await prisma.mesa.findMany({
        where,
        skip,
        take: safeLimit,
        orderBy: {
          numero: order,
        },
      });

    return {
      success: true,
      message: "Lista de mesas",
      data: mesas,
      pagination: {
        page: safePage,
        limit: safeLimit,
        total,
        totalPages:
          Math.ceil(total / safeLimit),
      },
    };
  }

  // =========================================================
  // MESAS DISPONIBLES
  // =========================================================

  async getMesasDisponibles(
    fecha?: string
  ) {
    let fechaReserva: Date | undefined;

    if (fecha) {
      const parsedDate = new Date(fecha);

      if (
        Number.isNaN(
          parsedDate.getTime()
        )
      ) {
        throw new Error(
          "Fecha de reserva inválida"
        );
      }

      fechaReserva = parsedDate;
    }

    // -------------------------------------------------------
    // SIN FECHA
    // -------------------------------------------------------

    if (!fechaReserva) {
      const mesas =
        await prisma.mesa.findMany({
          where: {
            deletedAt: null,
            disponible: true,
          },
          orderBy: {
            numero: "asc",
          },
        });

      return {
        success: true,
        message: "Mesas disponibles",
        data: mesas,
      };
    }

    // -------------------------------------------------------
    // NORMALIZAR AL MINUTO
    // -------------------------------------------------------

    const inicio = new Date(
      fechaReserva
    );

    inicio.setUTCSeconds(0, 0);

    const fin = new Date(inicio);

    fin.setUTCMinutes(
      fin.getUTCMinutes() + 1
    );

    console.log(
      "======================================"
    );

    console.log(
      "CONSULTA DE DISPONIBILIDAD"
    );

    console.log(
      "Fecha recibida:",
      fecha
    );

    console.log(
      "Fecha interpretada:",
      fechaReserva.toISOString()
    );

    console.log(
      "Inicio:",
      inicio.toISOString()
    );

    console.log(
      "Fin:",
      fin.toISOString()
    );

    // -------------------------------------------------------
    // BUSCAR MESAS DISPONIBLES
    // -------------------------------------------------------

    const mesas =
      await prisma.mesa.findMany({
        where: {
          deletedAt: null,

          // La mesa debe estar habilitada
          disponible: true,

          // No debe existir una reserva activa
          // dentro del minuto consultado.
          reservas: {
            none: {
              fecha: {
                gte: inicio,
                lt: fin,
              },

              estado: {
                in: [
                  EstadoReserva.PENDIENTE,
                  EstadoReserva.CONFIRMADA,
                ],
              },

              deletedAt: null,
            },
          },
        },

        orderBy: {
          numero: "asc",
        },
      });

    console.log(
      "Mesas disponibles:",
      mesas.map(
        (mesa) =>
          `${mesa.id} - ${mesa.numero}`
      )
    );

    console.log(
      "======================================"
    );

    return {
      success: true,
      message:
        "Mesas disponibles para la fecha y hora seleccionadas",
      data: mesas,
    };
  }

  // =========================================================
  // OBTENER UNA MESA
  // =========================================================

  async getMesaById(id: number) {
    const mesa =
      await prisma.mesa.findFirst({
        where: {
          id,
          deletedAt: null,
        },
      });

    if (!mesa) {
      throw new Error(
        "Mesa no encontrada"
      );
    }

    return {
      success: true,
      mesa,
    };
  }

  // =========================================================
  // CREAR MESA
  // =========================================================

  async createMesa(data: any) {
    const numero =
      String(data.numero ?? "").trim();

    const capacidad =
      Number(data.capacidad);

    const disponible =
      data.disponible !== false;

    if (!numero) {
      throw new Error(
        "El número o nombre de mesa es obligatorio"
      );
    }

    if (numero.length > 50) {
      throw new Error(
        "El número o nombre de mesa no puede superar 50 caracteres"
      );
    }

    if (
      !Number.isInteger(capacidad) ||
      capacidad <= 0
    ) {
      throw new Error(
        "La capacidad debe ser un número mayor a cero"
      );
    }

    const existente =
      await prisma.mesa.findFirst({
        where: {
          numero,
          deletedAt: null,
        },
      });

    if (existente) {
      throw new Error(
        `La mesa "${numero}" ya existe`
      );
    }

    try {
      const mesa =
        await prisma.mesa.create({
          data: {
            numero,
            capacidad,
            disponible,
          },
        });

      return {
        success: true,
        message:
          "Mesa creada correctamente",
        mesa,
      };
    } catch (error: any) {
      if (error?.code === "P2002") {
        throw new Error(
          `La mesa "${numero}" ya existe`
        );
      }

      throw error;
    }
  }

  // =========================================================
  // ACTUALIZAR MESA
  // =========================================================

  async updateMesa(
    id: number,
    data: any
  ) {
    const existe =
      await prisma.mesa.findFirst({
        where: {
          id,
          deletedAt: null,
        },
      });

    if (!existe) {
      throw new Error(
        "Mesa no encontrada"
      );
    }

    const numero =
      String(data.numero ?? "").trim();

    const capacidad =
      Number(data.capacidad);

    const disponible =
      data.disponible !== false;

    if (!numero) {
      throw new Error(
        "El número o nombre de mesa es obligatorio"
      );
    }

    if (numero.length > 50) {
      throw new Error(
        "El número o nombre de mesa no puede superar 50 caracteres"
      );
    }

    if (
      !Number.isInteger(capacidad) ||
      capacidad <= 0
    ) {
      throw new Error(
        "La capacidad debe ser un número mayor a cero"
      );
    }

    const duplicada =
      await prisma.mesa.findFirst({
        where: {
          numero,
          id: {
            not: id,
          },
          deletedAt: null,
        },
      });

    if (duplicada) {
      throw new Error(
        `La mesa "${numero}" ya existe`
      );
    }

    // Buscar únicamente reservas activas.
    const reservaActiva =
      await prisma.reserva.findFirst({
        where: {
          mesaId: id,
          estado: {
            in: [
              EstadoReserva.PENDIENTE,
              EstadoReserva.CONFIRMADA,
            ],
          },
          deletedAt: null,
        },
      });

    // Solo impedir cambiar la mesa a disponible
    // si realmente se está intentando modificar
    // el estado global de disponibilidad.
    if (
      reservaActiva &&
      existe.disponible !== disponible
    ) {
      throw new Error(
        "La mesa tiene una reserva pendiente o confirmada y no puede cambiar su estado de disponibilidad"
      );
    }

    try {
      const mesa =
        await prisma.mesa.update({
          where: {
            id,
          },
          data: {
            numero,
            capacidad,
            disponible,
          },
        });

      return {
        success: true,
        message:
          "Mesa actualizada correctamente",
        mesa,
      };
    } catch (error: any) {
      if (error?.code === "P2002") {
        throw new Error(
          `La mesa "${numero}" ya existe`
        );
      }

      throw error;
    }
  }

  // =========================================================
  // ELIMINAR MESA
  // =========================================================

  async deleteMesa(id: number) {
    const existe =
      await prisma.mesa.findFirst({
        where: {
          id,
          deletedAt: null,
        },
      });

    if (!existe) {
      throw new Error(
        "Mesa no encontrada"
      );
    }

    const reservaActiva =
      await prisma.reserva.findFirst({
        where: {
          mesaId: id,
          estado: {
            in: [
              EstadoReserva.PENDIENTE,
              EstadoReserva.CONFIRMADA,
            ],
          },
          deletedAt: null,
        },
      });

    if (reservaActiva) {
      throw new Error(
        "No se puede eliminar una mesa con una reserva pendiente o confirmada"
      );
    }

    await prisma.mesa.update({
      where: {
        id,
      },
      data: {
        deletedAt: new Date(),
      },
    });

    return {
      success: true,
      message:
        "Mesa eliminada correctamente",
    };
  }
}