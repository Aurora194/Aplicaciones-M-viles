import { Request, Response } from "express";
import { ReservaService } from "../services/reserva.service";
import { logger } from "../config/logger";


const service = new ReservaService();



    class ReservaController {



    async getReservas(req:Request,res:Response){


        try{


        const result = await service.getReservas(

        Number(req.query.page)||1,

        Number(req.query.limit)||10,

        req.query.cliente as string,

        req.query.mesa ? Number(req.query.mesa):undefined,

        req.query.fecha as string,

        req.query.estado as any,

        (req.query.order as "asc"|"desc") || "asc"

        );



        return res.json(result);



        }catch(error:any){


        return res.status(500).json({

        success:false,

        message:error.message

        });


    }


    }





    async getOne(req:Request,res:Response){


        try{


        const result = await service.getOne(

        Number(req.params.id)

        );


        return res.json(result);


        }catch(error:any){


        return res.status(404).json({

        success:false,

        message:error.message

        });


    }


    }





    async create(req:Request,res:Response){


        try{


        const result = await service.create(req.body);



        return res.status(201).json(result);



        }catch(error:any){


        return res.status(400).json({

        success:false,

        message:error.message

        });


    }


    }





    async update(req:Request,res:Response){


        try{


        const result = await service.update(

        Number(req.params.id),

        req.body

        );



        return res.json(result);



        }catch(error:any){


        return res.status(400).json({

        success:false,

        message:error.message

        });


    }


    }





    async remove(req:Request,res:Response){


        try{


        const result = await service.remove(

        Number(req.params.id)

        );



        return res.json(result);



        }catch(error:any){


        return res.status(400).json({

        success:false,

        message:error.message

        });


    }


    }


    }



export const controller = new ReservaController();