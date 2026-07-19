import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

export class MesaService {

  async getMesas(
    page: number,
    limit: number,
    search?: string,
    disponible?: boolean,
    order: "asc" | "desc" = "asc"
  ) {

    const skip = (page - 1) * limit;

    const where: any = {
      deletedAt: null
    };

    if (search) {

      where.numero = {
        equals: Number(search)
      };

    }

    if (disponible !== undefined) {

      where.disponible = disponible;

    }

    const total = await prisma.mesa.count({
      where
    });

    const mesas = await prisma.mesa.findMany({

      where,

      skip,

      take: limit,

      orderBy: {
        numero: order
      }

    });

    return {

      success: true,

      message: "Lista de mesas",

      data: mesas,

      pagination: {

        page,

        limit,

        total,

        totalPages: Math.ceil(total / limit)

      }

    };

  }

  async getMesaById(id: number) {

    const mesa = await prisma.mesa.findFirst({

      where: {

        id,

        deletedAt: null

      }

    });

    if (!mesa) {

      throw new Error();

    }

    return {

      success: true,

      mesa

    };

  }

  async createMesa(data: any) {

    const mesa = await prisma.mesa.create({

      data

    });

    return {

      success: true,

      message: "Mesa creada correctamente",

      mesa

    };

  }

  async updateMesa(id: number, data: any) {

    const existe = await prisma.mesa.findFirst({

      where: {

        id,

        deletedAt: null

      }

    });

    if (!existe) {

      throw new Error();

    }

    const mesa = await prisma.mesa.update({

      where: {

        id

      },

      data

    });

    return {

      success: true,

      message: "Mesa actualizada correctamente",

      mesa

    };

  }

  async deleteMesa(id: number) {

    const existe = await prisma.mesa.findFirst({

      where: {

        id,

        deletedAt: null

      }

    });

    if (!existe) {

      throw new Error();

    }

    await prisma.mesa.update({

      where: {

        id

      },

      data: {

        deletedAt: new Date()

      }

    });

    return {

      success: true,

      message: "Mesa eliminada correctamente"

    };

  }

}