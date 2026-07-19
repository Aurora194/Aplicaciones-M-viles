import { Request, Response } from "express";
import { UserService } from "../services/user.service";
import { logger } from "../config/logger";

const service = new UserService();

class UserController {

  async getUsers(req: Request, res: Response) {
    try {
      logger.info("Consulta de usuarios");
      const page = Number(req.query.page) || 1;
      const limit = Number(req.query.limit) || 10;
      const search = req.query.search as string;
      const rol = req.query.rol as any;

      const result = await service.getUsers(page, limit, search, rol);

      return res.status(200).json(result);

    } catch (error) {
      console.error(error);

      return res.status(500).json({
        success: false,
        message: "Error interno del servidor"
      });
    }
  }

  async getUserById(req: Request, res: Response) {
    try {

      const id = Number(req.params.id);

      const result = await service.getUserById(id);

      return res.status(200).json(result);

    } catch (error) {

      return res.status(404).json({
        success: false,
        message: "Usuario no encontrado"
      });

    }
  }

  async updateUser(req: Request, res: Response) {

    try {
      const id = Number(req.params.id);

      logger.info(`Usuario ${id} actualizado`);

      const result = await service.updateUser(id, req.body);

      return res.status(200).json(result);

    } catch (error) {

      console.error(error);

      return res.status(500).json({
        success: false,
        message: "No fue posible actualizar"
      });

    }
  }

  async deleteUser(req: Request, res: Response) {

  try {

    const id = Number(req.params.id);

    const result = await service.deleteUser(id);

    logger.info(`Usuario ${id} eliminado correctamente`);

    return res.status(200).json(result);

  } catch (error) {

    logger.error(error);

    return res.status(500).json({
      success: false,
      message: "No fue posible eliminar"
    });

  }

}

}

export const controller = new UserController();