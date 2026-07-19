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

        if (!roles.includes(user.rol)) {

            return res.status(403).json({

                success: false,

                message: "No tiene permisos para realizar esta acción."

            });

        }

        next();

    };

}