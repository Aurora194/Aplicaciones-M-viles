import { Request, Response, NextFunction } from "express";

export function authorizeRole(...roles: string[]) {

    return (
        req: Request,
        res: Response,
        next: NextFunction
    ) => {

        const user = (req as any).user;

        if (!user) {

            return res.status(401).json({

                success: false,

                message: "Usuario no autenticado."

            });

        }

        const userRole = String(user.rol || user.role || "").trim().toUpperCase();
        const allowedRoles = roles.map((role) => role.trim().toUpperCase());

        if (!allowedRoles.includes(userRole)) {

            return res.status(403).json({

                success: false,

                message: "No tiene permisos para realizar esta acción."

            });

        }

        next();

    };

}