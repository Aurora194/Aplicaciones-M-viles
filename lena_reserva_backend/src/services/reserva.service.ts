import prisma from "../config/prisma";
import {

getCache,

setCache,

deleteCache

} from "./cache.service";

export async function getReservas(){

    const cache=await getCache("reservas");

    if(cache){

        console.log("CACHE");

        return cache;

    }

    console.log("MYSQL");

    const reservas=await prisma.reserva.findMany({

        include:{

            usuario:true,

            mesa:true

        }

    });

    await setCache(

        "reservas",

        reservas,

        60

    );

    return reservas;

}

export function getReserva(id:number){

    return prisma.reserva.findUnique({

        where:{id},

        include:{

            usuario:true,

            mesa:true

        }

    });

}

export async function createReserva(data:any){

    const reserva = await prisma.reserva.create({

        data

    });

    await deleteCache("reservas");

    return reserva;

}

export async function updateReserva(

    id:number,

    data:any

){

    const reserva = await prisma.reserva.update({

        where:{id},

        data

    });

    await deleteCache("reservas");

    return reserva;

}

export async function deleteReserva(id:number){

    const reserva = await prisma.reserva.delete({

        where:{id}

    });

    await deleteCache("reservas");

    return reserva;

}

export async function mesaDisponible(

    mesaId:number,

    fecha:Date

){

    return prisma.reserva.findFirst({

        where:{

            mesaId,

            fecha

        }

    });

}