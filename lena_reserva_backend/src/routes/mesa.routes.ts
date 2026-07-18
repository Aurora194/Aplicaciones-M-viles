import { Router } from "express";

import * as mesaController from "../controllers/mesa.controller";

import { authenticateToken } from "../middleware/auth.middleware";

import { authorizeRole } from "../middleware/role.middleware";

import { validate } from "../middleware/validate.middleware";

import { mesaSchema } from "../validations/mesa.validation";

const router = Router();

/*
============================
Consultas públicas
============================
*/

router.get(

    "/disponibles",

    mesaController.disponibles

);

/*
============================
Administrador
============================
*/

router.get(

    "/",

    authenticateToken,

    authorizeRole("ADMIN"),

    mesaController.list

);

router.get(

    "/:id",

    authenticateToken,

    authorizeRole("ADMIN"),

    mesaController.getOne

);

router.post(

    "/",

    authenticateToken,

    authorizeRole("ADMIN"),

    validate(mesaSchema),

    mesaController.create

);

router.put(

    "/:id",

    authenticateToken,

    authorizeRole("ADMIN"),

    validate(mesaSchema),

    mesaController.update

);

router.delete(

    "/:id",

    authenticateToken,

    authorizeRole("ADMIN"),

    mesaController.remove

);

export default router;