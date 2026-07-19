import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

export class MesaService {

  async getMesas(
    page = 1,
    limit = 10,
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

    const total = await prisma.mesa.count({ where });

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
      data: mesas,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit)
      }
    };
  }

  async deleteMesa(id: number) {

    const mesa = await prisma.mesa.findFirst({
      where: {
        id,
        deletedAt: null
      }
    });

    if (!mesa) {
      throw new Error("Mesa no encontrada");
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