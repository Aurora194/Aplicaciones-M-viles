import { Request, Response, NextFunction } from "express";

import logger from "../utils/logger";

export function errorHandler(

err:any,

req:Request,

res:Response,

next:NextFunction

){

    logger.error(err.message);

    return res.status(

        err.statusCode||500

    ).json({

        success:false,

        message:err.message||"Error interno del servidor"

    });

}