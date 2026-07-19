import { Request, Response, NextFunction } from "express";
import { verifyAccessToken } from "../utils/jwt";

export function authenticateToken(
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

    const token = authHeader.split(" ")[1];

    try {

        const decoded = verifyAccessToken(token);

        (req as any).user = decoded;

        next();

    } catch {

        return res.status(401).json({

            success: false,

            message: "Token inválido."

        });

    }

}