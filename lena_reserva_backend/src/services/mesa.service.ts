import prisma from "../config/prisma";

export function getMesas() {

    return prisma.mesa.findMany({

        orderBy: {

            numero: "asc"

        }

    });

}

export function getMesa(id: number) {

    return prisma.mesa.findUnique({

        where: { id }

    });

}

export function createMesa(data: any) {

    return prisma.mesa.create({

        data

    });

}

export function updateMesa(

    id: number,

    data: any

) {

    return prisma.mesa.update({

        where: { id },

        data

    });

}

export function deleteMesa(id: number) {

    return prisma.mesa.delete({

        where: { id }

    });

}

export function mesasDisponibles() {

    return prisma.mesa.findMany({

        where: {

            disponible: true

        },

        orderBy: {

            numero: "asc"

        }

    });

}