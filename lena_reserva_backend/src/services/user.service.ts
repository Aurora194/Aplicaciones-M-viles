import prisma from "../config/prisma";

interface GetUsersParams {
    page?: number;
    limit?: number;
    search?: string;
    rol?: string;
    sortBy?: string;
    order?: "asc" | "desc";
}

export async function getUsers(params: GetUsersParams) {

    const page = Number(params.page) || 1;

    const limit = Number(params.limit) || 10;

    const skip = (page - 1) * limit;

    const where: any = {

        deletedAt: null

    };

    if (params.search) {

        where.OR = [

            {

                nombre: {

                    contains: params.search

                }

            },

            {

                apellido: {

                    contains: params.search

                }

            },

            {

                correo: {

                    contains: params.search

                }

            }

        ];

    }

    if (params.rol) {

        where.rol = params.rol;

    }

    const users = await prisma.usuario.findMany({

        where,

        skip,

        take: limit,

        orderBy: {

            [params.sortBy || "id"]:

                params.order || "asc"

        },

        select: {

            id: true,

            nombre: true,

            apellido: true,

            correo: true,

            telefono: true,

            rol: true,

            createdAt: true

        }

    });

    const total = await prisma.usuario.count({

        where

    });

    return {

        data: users,

        pagination: {

            total,

            page,

            limit,

            totalPages: Math.ceil(total / limit)

        }

    };

}

export async function getUserById(id: number) {

    return prisma.usuario.findFirst({

        where: {

            id,

            deletedAt: null

        }

    });

}

export async function updateUser(

    id: number,

    data: any

) {

    return prisma.usuario.update({

        where: {

            id

        },

        data

    });

}

export async function deleteUser(id: number) {

    return prisma.usuario.update({

        where: {

            id

        },

        data: {

            deletedAt: new Date()

        }

    });

}