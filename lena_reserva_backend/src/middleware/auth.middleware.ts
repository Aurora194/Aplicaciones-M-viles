import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";

const SECRET = process.env.JWT_SECRET || "lena_reserva_secret";

export function authenticateToken(
    req: Request,
    res: Response,
    next: NextFunction
) {

    const authHeader = req.headers.authorization;

    if (!authHeader) {

        return res.status(401).json({
            success: false,
            message: "Token no proporcionado."
        });

    }

    const token = authHeader.split(" ")[1];

    try {

        const payload = jwt.verify(token, SECRET) as any;

        req.user = {
            id: payload.id,
            correo: payload.correo,
            rol: payload.rol
        };

        next();

    } catch {

        return res.status(401).json({
            success: false,
            message: "Token inválido."
        });

    }

}