import { Request, Response, NextFunction } from "express";
import { verifyAccessToken } from "../utils/jwt";
import prisma from "../config/prisma";

export async function authenticateToken(
    req: Request,
    res: Response,
    next: NextFunction
) {

    const authHeader = req.headers.authorization;

    if (!authHeader) {

        return res.status(401).json({

            success: false,

            message: "Token requerido."

        });

    }

    const [scheme, token] = authHeader.split(" ");

    if (scheme?.toLowerCase() !== "bearer" || !token) {
        return res.status(401).json({
            success: false,
            message: "Formato de token inválido."
        });
    }

    try {

        const decoded = verifyAccessToken(token) as { id?: number };
        const usuario = decoded.id
            ? await prisma.usuario.findFirst({
                where: { id: decoded.id, deletedAt: null },
                select: { id: true, correo: true, rol: true }
            })
            : null;

        if (!usuario) {
            return res.status(401).json({
                success: false,
                message: "Usuario no encontrado o inactivo."
            });
        }

        (req as any).user = {
            ...usuario,
            rol: String(usuario.rol).trim().toUpperCase()
        };

        next();

    } catch {

        return res.status(401).json({

            success: false,

            message: "Token inválido."

        });

    }

}