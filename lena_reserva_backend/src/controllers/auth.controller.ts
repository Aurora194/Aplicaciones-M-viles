import { Request, Response } from "express";

import {
    createUser,
    findUserByEmail
} from "../services/auth.service";

import {
    hashPassword,
    comparePassword
} from "../utils/password";

import { generateAccessToken } from "../utils/jwt";

import { success } from "../utils/response";

import ApiError from "../utils/ApiError";

export async function register(

    req: Request,

    res: Response

) {

    try {

        const {

            nombre,

            apellido,

            correo,

            telefono,

            password

        } = req.body;

        const userExists = await findUserByEmail(correo);

        if (userExists) {

            throw new ApiError(

                409,

                "El correo ya está registrado."

            );

        }

        const hashedPassword = await hashPassword(password);

        const user = await createUser({

            nombre,

            apellido,

            correo,

            telefono,

            password: hashedPassword

        });

        res.status(201).json(

            success(

                user,

                "Usuario registrado correctamente."

            )

        );

    } catch (error: any) {

        if (error instanceof ApiError) {

            return res.status(error.statusCode).json({

                success: false,

                message: error.message

            });

        }

        return res.status(500).json({

            success: false,

            message: "Error interno del servidor."

        });

    }

}

export async function login(

    req: Request,

    res: Response

) {

    try {

        const {

            correo,

            password

        } = req.body;

        const user = await findUserByEmail(correo);

        if (!user) {

            throw new ApiError(

                401,

                "Credenciales incorrectas."

            );

        }

        const validPassword = await comparePassword(

            password,

            user.password

        );

        if (!validPassword) {

            throw new ApiError(

                401,

                "Credenciales incorrectas."

            );

        }

        const token = generateAccessToken(user);

        res.status(200).json(

            success(

                {

                    token,

                    usuario: {

                        id: user.id,

                        nombre: user.nombre,

                        correo: user.correo,

                        rol: user.rol

                    }

                },

                "Inicio de sesión exitoso."

            )

        );

    } catch (error: any) {

        if (error instanceof ApiError) {

            return res.status(error.statusCode).json({

                success: false,

                message: error.message

            });

        }

        return res.status(500).json({

            success: false,

            message: "Error interno del servidor."

        });

    }

}
