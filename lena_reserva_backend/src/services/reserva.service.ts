import { PrismaClient, EstadoReserva } from "@prisma/client";

const prisma = new PrismaClient();

export class ReservaService {

    async getReservas(
        page: number,
        limit: number,
        cliente?: string,
        mesa?: number,
        fecha?: string,
        estado?: EstadoReserva,
        order: "asc" | "desc" = "asc"
    ) {

        const skip = (page - 1) * limit;

        const where: any = {};

        if (cliente) {

            where.usuario = {

                OR: [
                    {
                        nombre: {
                            contains: cliente
                        }
                    },
                    {
                        apellido: {
                            contains: cliente
                        }
                    },
                    {
                        correo: {
                            contains: cliente
                        }
                    }
                ]

            };

        }


        if (mesa) {

            where.mesaId = mesa;

        }


        if (fecha) {

            const inicio = new Date(fecha);

            const fin = new Date(fecha);

            fin.setDate(fin.getDate() + 1);


            where.fecha = {

                gte: inicio,

                lt: fin

            };

        }


        if (estado) {

            where.estado = estado;

        }


        const total = await prisma.reserva.count({
            where
        });


        const reservas = await prisma.reserva.findMany({

            where,

            include: {

                usuario: {

                    select:{
                        id:true,
                        nombre:true,
                        apellido:true,
                        correo:true
                    }

                },

                mesa:{
                    select:{
                        id:true,
                        numero:true,
                        capacidad:true
                    }
                }

            },

            skip,

            take:limit,

            orderBy:{
                fecha:order
            }

        });


        return {

            success:true,

            message:"Lista de reservas",

            data:reservas,

            pagination:{
                page,
                limit,
                total,
                totalPages:Math.ceil(total / limit)
            }

        };

    }



    async getOne(id:number){


        const reserva = await prisma.reserva.findUnique({

            where:{
                id
            },

            include:{
                usuario:true,
                mesa:true
            }

        });


        if(!reserva){

            throw new Error("Reserva no encontrada");

        }


        return {

            success:true,

            data:reserva

        };


    }




    async create(data:any){


        const usuario = await prisma.usuario.findUnique({

            where:{
                id:data.usuarioId
            }

        });


        if(!usuario){

            throw new Error("Usuario no existe");

        }



        const mesa = await prisma.mesa.findUnique({

            where:{
                id:data.mesaId
            }

        });


        if(!mesa){

            throw new Error("Mesa no existe");

        }



        if(!mesa.disponible){

            throw new Error("Mesa no disponible");

        }



        const reserva = await prisma.reserva.create({

            data,

            include:{
                usuario:true,
                mesa:true
            }

        });



        await prisma.mesa.update({

            where:{
                id:data.mesaId
            },

            data:{
                disponible:false
            }

        });


        return {

            success:true,

            message:"Reserva creada correctamente",

            data:reserva

        };


    }





    async update(id:number,data:any){


        const existe = await prisma.reserva.findUnique({

            where:{
                id
            }

        });


        if(!existe){

            throw new Error("Reserva no encontrada");

        }



        const reserva = await prisma.reserva.update({

            where:{
                id
            },

            data,

            include:{
                usuario:true,
                mesa:true
            }

        });



        return {

            success:true,

            message:"Reserva actualizada",

            data:reserva

        };


    }





    async remove(id:number){


        const reserva = await prisma.reserva.findUnique({

            where:{
                id
            }

        });


        if(!reserva){

            throw new Error("Reserva no encontrada");

        }



        await prisma.reserva.delete({

            where:{
                id
            }

        });



        await prisma.mesa.update({

            where:{
                id:reserva.mesaId
            },

            data:{
                disponible:true
            }

        });



        return {

            success:true,

            message:"Reserva eliminada correctamente"

        };


    }

}