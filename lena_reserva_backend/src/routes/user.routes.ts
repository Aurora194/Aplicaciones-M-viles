import { Router } from "express";

import {

    authenticateToken

} from "../middleware/auth.middleware";

import { authorizeRole } from "../middleware/role.middleware";

import * as userController from "../controllers/user.controller";

import { validate } from "../middleware/validate.middleware";

import { updateUserSchema } from "../validations/user.validation";
const router = Router();

router.get(

    "/perfil",

    authenticateToken,

    (req, res) => {

        res.status(200).json({

            success: true,

            usuario: (req as any).user

        });

    }

);

router.get(

    "/admin",

    authenticateToken,

    authorizeRole("ADMIN"),

    (req, res) => {

        res.json({

            success: true,

            mensaje: "Bienvenido administrador."

        });

    }

);

router.get(

"/",

authenticateToken,

authorizeRole("ADMIN"),

userController.listUsers

);

router.get(

"/:id",

authenticateToken,

userController.getOne

);

router.put(

"/:id",

authenticateToken,

validate(updateUserSchema),

userController.update

);

router.delete(

"/:id",

authenticateToken,

authorizeRole("ADMIN"),

userController.remove

);

export default router;