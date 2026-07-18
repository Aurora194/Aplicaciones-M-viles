import prisma from "../config/prisma";

export async function findUserByEmail(

    correo: string

) {

    return prisma.usuario.findUnique({

        where: {

            correo

        }

    });

}

export async function createUser(data: any) {

    return prisma.usuario.create({

        data

    });

}