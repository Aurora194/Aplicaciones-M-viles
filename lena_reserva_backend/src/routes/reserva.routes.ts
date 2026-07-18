import { Router } from "express";

import * as controller from "../controllers/reserva.controller";

import { authenticateToken } from "../middleware/auth.middleware";

import { authorizeRole } from "../middleware/role.middleware";

import { validate } from "../middleware/validate.middleware";

import { reservaSchema } from "../validations/reserva.validation";

const router=Router();

router.get(

"/",

authenticateToken,

authorizeRole("ADMIN"),

controller.list

);

router.get(

"/:id",

authenticateToken,

controller.getOne

);

router.post(

"/",

authenticateToken,

validate(reservaSchema),

controller.create

);

router.put(

"/:id",

authenticateToken,

validate(reservaSchema),

controller.update

);

router.delete(

"/:id",

authenticateToken,

controller.remove

);

export default router;