import { Request, Response } from "express";
import * as service from "../services/mesa.service";
import { success } from "../utils/response";
import ApiError from "../utils/ApiError";

export async function list(req: Request, res: Response) {

    const mesas = await service.getMesas();

    res.json(

    success(

        mesas,

        "Mesas obtenidas correctamente."

    )

);

}

export async function disponibles(req: Request, res: Response) {

    const mesas = await service.mesasDisponibles();

    res.json(

    success(

        mesas,

        "Mesas disponibles obtenidas correctamente."

    )

);

}

export async function getOne(req: Request, res: Response) {

    const mesa = await service.getMesa(Number(req.params.id));

    if (!mesa) {


        throw new ApiError(

            404,

            "Mesa no encontrado."

        );

    }

    res.json(

    success(

        mesa,

        "Mesa obtenida correctamente."

    )

);

}

export async function create(req: Request, res: Response) {

    const mesa = await service.createMesa(req.body);

    res.status(201).json(

    success(

        mesa,

        "Mesa creada correctamente."

    )

);

}

export async function update(req: Request, res: Response) {

    const mesa = await service.updateMesa(

        Number(req.params.id),

        req.body

    );

    res.json(

    success(

        mesa,

        "Mesa actualizada correctamente."

    )

);
}

export async function remove(req: Request, res: Response) {

    await service.deleteMesa(

        Number(req.params.id)

    );

    res.json(

        success(

            null,

            "Mesa eliminada correctamente."

        )

    );

}