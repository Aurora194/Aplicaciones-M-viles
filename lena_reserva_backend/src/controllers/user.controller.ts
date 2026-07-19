import { Request, Response } from "express";
import * as userService from "../services/user.service";

export async function getUsers(req: Request, res: Response) {

    try {

        const {
            page,
            limit,
            search,
            rol,
            sortBy,
            order
        } = req.query;

        const users = await userService.getUsers({

            page: Number(page),

            limit: Number(limit),

            search: search as string,

            rol: rol as string,

            sortBy: sortBy as string,

            order: order as "asc" | "desc"

        });

        return res.status(200).json({

            success: true,

            ...users

        });

    } catch (error) {

        console.error(error);

        return res.status(500).json({

            success: false,

            message: "Error interno del servidor."

        });

    }

}

export async function getUserById(req: Request, res: Response) {

    try {

        const id = Number(req.params.id);

        const user = await userService.getUserById(id);

        if (!user) {

            return res.status(404).json({

                success: false,

                message: "Usuario no encontrado."

            });

        }

        return res.json({

            success: true,

            user

        });

    } catch (error) {

        console.error(error);

        return res.status(500).json({

            success: false,

            message: "Error interno."

        });

    }

}

export async function updateUser(req: Request, res: Response) {

    try {

        const id = Number(req.params.id);

        const user = await userService.updateUser(

            id,

            req.body

        );

        return res.json({

            success: true,

            message: "Usuario actualizado correctamente.",

            user

        });

    } catch (error) {

        console.error(error);

        return res.status(500).json({

            success: false,

            message: "Error interno."

        });

    }

}

export async function deleteUser(req: Request, res: Response) {

    try {

        const id = Number(req.params.id);

        await userService.deleteUser(id);

        return res.json({

            success: true,

            message: "Usuario eliminado correctamente."

        });

    } catch (error) {

        console.error(error);

        return res.status(500).json({

            success: false,

            message: "Error interno."

        });

    }

}