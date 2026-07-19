import { Request, Response } from "express";
import { Rol } from "@prisma/client";
import bcrypt from "bcryptjs";
import prisma from "../config/prisma";

import {
generateAccessToken,
generateRefreshToken,
verifyRefreshToken
} from "../utils/jwt";

import * as refreshService from "../services/refreshToken.service";


export async function register(req: Request,res: Response){

    try {

        const {
            nombre,
            apellido,
            correo,
            telefono,
            password,
            rol
        } = req.body;


        const existe = await prisma.usuario.findUnique({
            where:{
                correo
            }
        });


        if(existe){

            return res.status(400).json({

                success:false,

                message:"El correo ya está registrado."

            });

        }


        const passwordHash =
            await bcrypt.hash(password,10);



        const usuario =
            await prisma.usuario.create({

                data:{

                    nombre,

                    apellido,

                    correo,

                    telefono,

                    password:passwordHash,

                    rol: rol 
                    ? Rol[rol as keyof typeof Rol]
                    : Rol.CLIENTE

                }

            });



        return res.status(201).json({

            success:true,

            message:"Usuario creado correctamente",

            usuario

        });



    }catch(error){

        console.error("ERROR REGISTER:",error);

        return res.status(500).json({

            success:false,

            message:"Error interno del servidor."

        });

    }

}


export async function login(req: Request, res: Response) {

    try {

        const {

            correo,

            password

        } = req.body;

        const usuario = await prisma.usuario.findUnique({

            where: {

                correo

            }

        });

        if (!usuario) {

            return res.status(401).json({

                success: false,

                message: "Correo o contraseña incorrectos."

            });

        }

        const match = await bcrypt.compare(

            password,

            usuario.password

        );

        if (!match) {

            return res.status(401).json({

                success: false,

                message: "Correo o contraseña incorrectos."

            });

        }

        const accessToken = generateAccessToken(usuario);

        const refreshToken = generateRefreshToken(usuario);

        const expiresAt = new Date();

        expiresAt.setDate(

            expiresAt.getDate() + 7

        );

        await refreshService.saveRefreshToken(

            usuario.id,

            refreshToken,

            expiresAt

        );

        return res.status(200).json({

            success: true,

            accessToken,

            refreshToken

        });

    }

    catch (error) {

        console.error("ERROR COMPLETO:", error);

        return res.status(500).json({

            success: false,

            message: "Error interno del servidor."

        });

    }

}


export async function logout(req: Request, res: Response) {

    try {

        const {

            refreshToken

        } = req.body;

        if (!refreshToken) {

            return res.status(400).json({

                success: false,

                message: "Refresh Token requerido."

            });

        }

        await refreshService.deleteRefreshToken(

            refreshToken

        );

        return res.status(200).json({

            success: true,

            message: "Sesión cerrada correctamente."

        });

    }

    catch (error) {

        console.error("ERROR COMPLETO:", error);

        return res.status(500).json({

            success: false,

            message: "Error interno del servidor."

        });

    }

}

export async function refresh(
    req: Request,
    res: Response
) {
    try {

        const { refreshToken } = req.body;

        if (!refreshToken) {

            return res.status(401).json({
                success: false,
                message: "Refresh Token requerido."
            });

        }

        const stored =
            await refreshService.findRefreshToken(refreshToken);

        if (!stored) {

            return res.status(401).json({
                success: false,
                message: "Refresh Token inválido."
            });

        }

        if (stored.expiresAt < new Date()) {

            await refreshService.deleteRefreshToken(refreshToken);

            return res.status(401).json({
                success: false,
                message: "Refresh Token expirado."
            });

        }

        const usuario = await prisma.usuario.findUnique({

            where: {

                id: stored.usuarioId

            }

        });

        if (!usuario) {

            return res.status(404).json({

                success: false,

                message: "Usuario no encontrado."

            });

        }

        const accessToken =
            generateAccessToken(usuario);

        return res.json({

            success: true,

            accessToken

        });

    }

    catch (error) {

        console.error("ERROR COMPLETO:", error);

        return res.status(500).json({

            success: false,

            message: "Error interno."

        });

    }

}