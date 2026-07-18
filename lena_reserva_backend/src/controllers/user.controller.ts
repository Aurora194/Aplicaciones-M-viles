import { Request, Response } from "express";
import * as service from "../services/user.service";
import { success } from "../utils/response";
import ApiError from "../utils/ApiError";

export async function listUsers(

req:Request,

res:Response

){

    const users=await service.getUsers();

    res.json(

        success(

            users,

            "Usuarios obtenidos correctamente."

        )

    );

}

export async function getOne(

req:Request,

res:Response

){

    const user=await service.getUser(

        Number(req.params.id)

    );

    if(!user){

    throw new ApiError(

        404,

        "Usuario no encontrado."

    );

    }

    res.json(

        success(

            user,

            "Usuario obtenido correctamente."

        )

    );

}

export async function update(

req:Request,

res:Response

){

    const user=await service.updateUser(

        Number(req.params.id),

        req.body

    );

    res.json(

        success(

            user,

            "Usuario obtenido correctamente."

        )

    );

}

export async function remove(

req:Request,

res:Response

){

    await service.deleteUser(

        Number(req.params.id)

    );

    res.json(

        success(

            null,

            "Usuario eliminada correctamente."

        )

    );

}