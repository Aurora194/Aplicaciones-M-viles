import { PrismaClient, Rol } from "@prisma/client";

const prisma = new PrismaClient();

export class UserService {

  async getUsers(
    page: number,
    limit: number,
    search?: string,
    rol?: Rol
  ) {

    const skip = (page - 1) * limit;

    const where: any = {
      deletedAt: null
    };

    // Buscar por nombre, apellido o correo
    if (search) {
      where.OR = [
        {
          nombre: {
            contains: search
            // mode: "insensitive" // Solo si tu versión de Prisma/MySQL lo soporta
          }
        },
        {
          apellido: {
            contains: search
            // mode: "insensitive"
          }
        },
        {
          correo: {
            contains: search
            // mode: "insensitive"
          }
        }
      ];
    }

    // Filtrar por rol
    if (rol) {
      where.rol = rol;
    }

    const total = await prisma.usuario.count({
      where
    });

    const usuarios = await prisma.usuario.findMany({
      where,
      skip,
      take: limit,
      orderBy: {
        id: "asc"
      },
      select: {
        id: true,
        nombre: true,
        apellido: true,
        correo: true,
        telefono: true,
        rol: true,
        createdAt: true,
        updatedAt: true
      }
    });

    return {
      success: true,
      message: "Lista de usuarios",
      data: usuarios,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit)
      }
    };
  }

  async getUserById(id: number) {

    const usuario = await prisma.usuario.findFirst({
      where: {
        id,
        deletedAt: null
      },
      select: {
        id: true,
        nombre: true,
        apellido: true,
        correo: true,
        telefono: true,
        rol: true,
        createdAt: true,
        updatedAt: true
      }
    });

    if (!usuario) {
      throw new Error("Usuario no encontrado");
    }

    return {
      success: true,
      usuario
    };
  }

  async updateUser(id: number, data: any) {

    // Verificar que el usuario exista
    const existe = await prisma.usuario.findFirst({
      where: {
        id,
        deletedAt: null
      }
    });

    if (!existe) {
      throw new Error("Usuario no encontrado");
    }

    const usuario = await prisma.usuario.update({
      where: {
        id
      },
      data,
      select: {
        id: true,
        nombre: true,
        apellido: true,
        correo: true,
        telefono: true,
        rol: true,
        createdAt: true,
        updatedAt: true
      }
    });

    return {
      success: true,
      message: "Usuario actualizado correctamente",
      usuario
    };
  }

  async deleteUser(id: number) {

    // Verificar que exista
    const existe = await prisma.usuario.findFirst({
      where: {
        id,
        deletedAt: null
      }
    });

    if (!existe) {
      throw new Error("Usuario no encontrado");
    }

    // Soft Delete
    await prisma.usuario.update({
      where: {
        id
      },
      data: {
        deletedAt: new Date()
      }
    });

    return {
      success: true,
      message: "Usuario eliminado correctamente"
    };
  }

}