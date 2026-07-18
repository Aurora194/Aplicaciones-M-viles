import { Request, Response } from "express";
import * as service from "../services/reserva.service";
import {sendReservationNotification } from "../jobs/reservation.job";
import { success } from "../utils/response";
import ApiError from "../utils/ApiError";

export async function list(

req:Request,

res:Response

){

    const reservas=await service.getReservas();

    res.json(reservas);

}

export async function create(

req:Request,

res:Response

){

    const existe=await service.mesaDisponible(

        req.body.mesaId,

        new Date(req.body.fecha)

    );

    if(existe){

        return res.status(409).json({

            success:false,

            message:"La mesa ya posee una reserva para esa fecha."

        });

    }

    const reserva=await service.createReserva(req.body);

    res.status(201).json(

    success(

        reserva,

        "Reserva creada correctamente."

        )

    );

    await sendReservationNotification(

    reserva

    );

}



export async function getOne(

req:Request,

res:Response

){

    const reserva=await service.getReserva(

        Number(req.params.id)

    );

    if(!reserva){

        throw new ApiError(

            404,

            "Reserva no encontrada."

        );

    }

    res.json(

        success(

            reserva,

            "Reserva obtenida correctamente."

        )

    );

}

export async function update(

req:Request,

res:Response

){

    const reserva=await service.updateReserva(

        Number(req.params.id),

        req.body

    );

    res.json(

    success(

        reserva,

        "Reserva actualizada correctamente."

    )

);

}

export async function remove(

req:Request,

res:Response

){

    await service.deleteReserva(

        Number(req.params.id)

    );

    res.json(

        success(

            null,

            "Reserva eliminada correctamente."

        )

    );

    

}