import prisma from "../config/prisma";

export function getUsers() {

    return prisma.usuario.findMany({

        orderBy:{

            id:"asc"

        }

    });

}

export function getUser(id:number){

    return prisma.usuario.findUnique({

        where:{id}

    });

}

export function updateUser(

    id:number,

    data:any

){

    return prisma.usuario.update({

        where:{id},

        data

    });

}

export function deleteUser(id:number){

    return prisma.usuario.delete({

        where:{id}

    });

}