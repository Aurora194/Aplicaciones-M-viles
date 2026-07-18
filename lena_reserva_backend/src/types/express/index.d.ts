import "express";

declare module "express-serve-static-core" {

    interface Request {

        user?: {

            id: number;

            correo: string;

            rol: string;

        };

    }

}

export {};