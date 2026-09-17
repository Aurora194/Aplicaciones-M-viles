import { Request, Response } from "express";
import { Rol } from "@prisma/client";
import bcrypt from "bcryptjs";
import prisma from "../config/prisma";
import { randomInt } from "crypto";
import { sendPasswordResetEmail } from "../services/email.service";

import {
  generateAccessToken,
  generateRefreshToken,
} from "../utils/jwt";

import * as refreshService from "../services/refreshToken.service";


export async function register(req: Request, res: Response) {
  try {
    const {
      nombre,
      apellido,
      correo,
      telefono,
      password,
    } = req.body;

    const nombreLimpio = String(nombre ?? "").trim();
    const apellidoLimpio = String(apellido ?? "").trim();
    const telefonoLimpio = String(telefono ?? "").trim();

    const nombreValido =
      /^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ]+(?:[\s'-][a-zA-ZáéíóúÁÉÍÓÚñÑüÜ]+)*$/;

    if (
      !nombreValido.test(nombreLimpio) ||
      !nombreValido.test(apellidoLimpio)
    ) {
      return res.status(422).json({
        success: false,
        message: "El nombre y apellido solo pueden contener letras.",
      });
    }

    if (!/^\d{1,10}$/.test(telefonoLimpio)) {
      return res.status(422).json({
        success: false,
        message: "El teléfono debe contener máximo 10 números.",
      });
    }

    const existe = await prisma.usuario.findUnique({
      where: {
        correo,
      },
    });

    if (existe) {
      return res.status(400).json({
        success: false,
        message: "El correo ya está registrado.",
      });
    }

    const passwordHash = await bcrypt.hash(password, 10);

    const usuario = await prisma.usuario.create({
      data: {
        nombre: nombreLimpio,
        apellido: apellidoLimpio,
        correo,
        telefono: telefonoLimpio,
        password: passwordHash,
        rol: Rol.CLIENTE,
      },
    });

    return res.status(201).json({
      success: true,
      message: "Usuario creado correctamente",
      usuario: {
        id: usuario.id,
        nombre: usuario.nombre,
        apellido: usuario.apellido,
        correo: usuario.correo,
        telefono: usuario.telefono,
        rol: usuario.rol,
      },
    });
  } catch (error: any) {
    console.error("ERROR REGISTER:", error);

    if (error?.name === "PrismaClientInitializationError") {
      return res.status(503).json({
        success: false,
        message:
          "La base de datos no está disponible. Inicie MySQL o Docker.",
      });
    }

    return res.status(500).json({
      success: false,
      message: "Error interno del servidor.",
    });
  }
}


export async function login(req: Request, res: Response) {
  try {
    const {
      correo,
      password,
    } = req.body;

    const usuario = await prisma.usuario.findUnique({
      where: {
        correo,
      },
    });

    if (!usuario || usuario.deletedAt) {
      return res.status(401).json({
        success: false,
        message: "Correo o contraseña incorrectos.",
      });
    }

    const match = await bcrypt.compare(
      password,
      usuario.password
    );

    if (!match) {
      return res.status(401).json({
        success: false,
        message: "Correo o contraseña incorrectos.",
      });
    }

    const accessToken = generateAccessToken(usuario);
    const refreshToken = generateRefreshToken(usuario);

    const expiresAt = new Date();

    expiresAt.setDate(
      expiresAt.getDate() + 7
    );

    await refreshService.saveRefreshToken(
      usuario.id,
      refreshToken,
      expiresAt
    );

    return res.status(200).json({
      success: true,
      accessToken,
      refreshToken,
      usuario: {
        id: usuario.id,
        nombre: usuario.nombre,
        apellido: usuario.apellido,
        correo: usuario.correo,
        rol: usuario.rol,
      },
    });
  } catch (error: any) {
    console.error("ERROR LOGIN:", error);

    if (error?.name === "PrismaClientInitializationError") {
      return res.status(503).json({
        success: false,
        message:
          "La base de datos no está disponible. Inicie MySQL o Docker.",
      });
    }

    return res.status(500).json({
      success: false,
      message: "Error interno del servidor.",
    });
  }
}


export async function logout(req: Request, res: Response) {
  try {
    const {
      refreshToken,
    } = req.body;

    if (!refreshToken) {
      return res.status(400).json({
        success: false,
        message: "Refresh Token requerido.",
      });
    }

    await refreshService.deleteRefreshToken(
      refreshToken
    );

    return res.status(200).json({
      success: true,
      message: "Sesión cerrada correctamente.",
    });
  } catch (error) {
    console.error("ERROR LOGOUT:", error);

    return res.status(500).json({
      success: false,
      message: "Error interno del servidor.",
    });
  }
}


export async function refresh(
  req: Request,
  res: Response
) {
  try {
    const {
      refreshToken,
    } = req.body;

    if (!refreshToken) {
      return res.status(401).json({
        success: false,
        message: "Refresh Token requerido.",
      });
    }

    const stored =
      await refreshService.findRefreshToken(
        refreshToken
      );

    if (!stored) {
      return res.status(401).json({
        success: false,
        message: "Refresh Token inválido.",
      });
    }

    if (stored.expiresAt < new Date()) {
      await refreshService.deleteRefreshToken(
        refreshToken
      );

      return res.status(401).json({
        success: false,
        message: "Refresh Token expirado.",
      });
    }

    const usuario =
      await prisma.usuario.findUnique({
        where: {
          id: stored.usuarioId,
        },
      });

    if (!usuario) {
      return res.status(404).json({
        success: false,
        message: "Usuario no encontrado.",
      });
    }

    const accessToken =
      generateAccessToken(usuario);

    return res.json({
      success: true,
      accessToken,
    });
  } catch (error) {
    console.error("ERROR REFRESH:", error);

    return res.status(500).json({
      success: false,
      message: "Error interno.",
    });
  }
}


/**
 * Solicitar recuperación de contraseña
 */
export async function forgotPassword(
  req: Request,
  res: Response
) {
  try {
    const correo = String(
      req.body.correo ?? ""
    )
      .trim()
      .toLowerCase();

    if (
      !correo ||
      !correo.includes("@")
    ) {
      return res.status(422).json({
        success: false,
        message:
          "Ingrese un correo electrónico válido.",
      });
    }

    const usuario =
      await prisma.usuario.findUnique({
        where: {
          correo,
        },
      });

    /*
     * Por seguridad no revelamos si el correo existe.
     */
    if (!usuario || usuario.deletedAt) {
      return res.status(200).json({
        success: true,
        message:
          "Si el correo está registrado, recibirá un código de recuperación.",
      });
    }

    /*
     * Invalidar códigos anteriores.
     */
    await prisma.passwordReset.updateMany({
      where: {
        usuarioId: usuario.id,
        usado: false,
      },
      data: {
        usado: true,
      },
    });

    /*
     * Generar código de 6 dígitos.
     */
    const codigo =
      randomInt(
        100000,
        1000000
      ).toString();

    /*
     * El código será válido durante 10 minutos.
     */
    const expiresAt = new Date(
      Date.now() +
        10 * 60 * 1000
    );

    await prisma.passwordReset.create({
      data: {
        usuarioId: usuario.id,
        codigo,
        expiresAt,
        usado: false,
      },
    });

    /*
     * Enviar código por correo.
     */
    await sendPasswordResetEmail(
      usuario.correo,
      usuario.nombre,
      codigo
    );

    return res.status(200).json({
      success: true,
      message:
        "Si el correo está registrado, recibirá un código de recuperación.",
    });
  } catch (error) {
    console.error(
      "ERROR FORGOT PASSWORD:",
      error
    );

    return res.status(500).json({
      success: false,
      message:
        "No fue posible procesar la recuperación de contraseña.",
    });
  }
}


/**
 * Restablecer contraseña
 */
export async function resetPassword(
  req: Request,
  res: Response
) {
  try {
    const correo = String(
      req.body.correo ?? ""
    )
      .trim()
      .toLowerCase();

    const codigo = String(
      req.body.codigo ?? ""
    ).trim();

    const nuevaPassword = String(
      req.body.nuevaPassword ?? ""
    );

    if (
      !correo ||
      !codigo ||
      !nuevaPassword
    ) {
      return res.status(422).json({
        success: false,
        message:
          "Correo, código y nueva contraseña son obligatorios.",
      });
    }

    if (!/^\d{6}$/.test(codigo)) {
      return res.status(422).json({
        success: false,
        message:
          "El código debe tener 6 dígitos.",
      });
    }

    if (nuevaPassword.length < 4) {
      return res.status(422).json({
        success: false,
        message:
          "La nueva contraseña debe tener al menos 4 caracteres.",
      });
    }

    const usuario =
      await prisma.usuario.findUnique({
        where: {
          correo,
        },
      });

    if (!usuario || usuario.deletedAt) {
      return res.status(400).json({
        success: false,
        message:
          "El código no es válido.",
      });
    }

    const reset =
      await prisma.passwordReset.findFirst({
        where: {
          usuarioId: usuario.id,
          codigo,
          usado: false,
          expiresAt: {
            gt: new Date(),
          },
        },
        orderBy: {
          createdAt: "desc",
        },
      });

    if (!reset) {
      return res.status(400).json({
        success: false,
        message:
          "El código es incorrecto, expiró o ya fue utilizado.",
      });
    }

    const passwordHash =
      await bcrypt.hash(
        nuevaPassword,
        10
      );

    await prisma.$transaction([
      prisma.usuario.update({
        where: {
          id: usuario.id,
        },
        data: {
          password: passwordHash,
        },
      }),

      prisma.passwordReset.update({
        where: {
          id: reset.id,
        },
        data: {
          usado: true,
        },
      }),

      /*
       * Cerrar sesiones anteriores
       * por seguridad.
       */
      prisma.refreshToken.deleteMany({
        where: {
          usuarioId: usuario.id,
        },
      }),
    ]);

    return res.status(200).json({
      success: true,
      message:
        "Contraseña actualizada correctamente.",
    });
  } catch (error) {
    console.error(
      "ERROR RESET PASSWORD:",
      error
    );

    return res.status(500).json({
      success: false,
      message:
        "No fue posible actualizar la contraseña.",
    });
  }
}