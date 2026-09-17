import { Request, Response } from "express";

import { EstadoReserva } from "@prisma/client";

import { GoogleGenAI } from "@google/genai";

import prisma from "../config/prisma";

const ai = new GoogleGenAI({
  apiKey: process.env.GEMINI_API_KEY,
});

const MODEL = "gemini-3.1-flash-lite";

type UserRole =
  | "ADMIN"
  | "CLIENTE"
  | "USUARIO"
  | string;

// =========================================================
// USUARIO AUTENTICADO
// =========================================================

function getUser(req: Request) {
  return (req as any).user ?? {};
}

// =========================================================
// ROL
// =========================================================

function getRole(req: Request): UserRole {
  const user = getUser(req);

  return String(
    user.rol ??
      user.role ??
      user.rolNombre ??
      "USUARIO",
  ).toUpperCase();
}

function isAdmin(role: UserRole): boolean {
  return role === "ADMIN";
}

// =========================================================
// ID USUARIO
// =========================================================

function getUserId(req: Request): number | null {
  const user = getUser(req);

  const id = Number(
    user.id ??
      user.userId ??
      user.usuarioId,
  );

  return Number.isFinite(id) ? id : null;
}

// =========================================================
// EXTRAER HORA
// =========================================================
//
// Ejemplos aceptados:
//
// 20:00
// 20
// 20 h
// 20 horas
// 20 hrs
// 20:30
// 20.30
//
// La hora se interpreta SIEMPRE como hora de Ecuador.
// =========================================================

function extraerHora(
  texto: string,
): {
  hora: number;
  minuto: number;
} | null {
  const patrones = [
    // 20:00
    // 08:30
    // 4:05
    /\b([01]?\d|2[0-3]):([0-5]\d)\b/i,

    // 20.00
    // 08.30
    /\b([01]?\d|2[0-3])\.([0-5]\d)\b/i,

    // 20 h
    // 20h
    // 20 hrs
    // 20 horas
    /\b([01]?\d|2[0-3])\s*(?:h|hrs?|horas?)\b/i,

    // 20
    // Se usa como último recurso.
    // Evitamos interpretar números mayores de 23 como horas.
    /\b([01]?\d|2[0-3])\b/i,
  ];

  for (const patron of patrones) {
    const match = texto.match(patron);

    if (!match) {
      continue;
    }

    const hora = Number(match[1]);
    const minuto = match[2]
      ? Number(match[2])
      : 0;

    if (
      Number.isInteger(hora) &&
      hora >= 0 &&
      hora <= 23 &&
      Number.isInteger(minuto) &&
      minuto >= 0 &&
      minuto <= 59
    ) {
      console.log("========================================");
      console.log("IA - HORA DETECTADA");
      console.log("Texto:", texto);
      console.log("Coincidencia:", match[0]);
      console.log("Hora:", hora);
      console.log("Minuto:", minuto);
      console.log("========================================");

      return {
        hora,
        minuto,
      };
    }
  }

  console.log("========================================");
  console.log("IA - NO SE DETECTÓ HORA");
  console.log("Texto:", texto);
  console.log("========================================");

  return null;
}

// =========================================================
// EXTRAER PERSONAS
// =========================================================

function extraerPersonas(
  texto: string,
): number | null {
  const patrones = [
    /para\s+(\d+)\s+personas?/i,
    /(\d+)\s+personas?/i,
    /mesa\s+para\s+(\d+)/i,
    /somos\s+(\d+)/i,
  ];

  for (const patron of patrones) {
    const match = texto.match(patron);

    if (match) {
      const personas = Number(match[1]);

      if (
        Number.isInteger(personas) &&
        personas > 0 &&
        personas <= 100
      ) {
        return personas;
      }
    }
  }

  return null;
}

// =========================================================
// OBTENER FECHA ACTUAL DE ECUADOR
// =========================================================
//
// Ecuador continental = UTC-5.
//
// No usamos directamente Date.now() como fecha local
// porque el servidor Docker puede estar configurado en UTC.
// =========================================================

function obtenerAhoraEcuador(): {
  anio: number;
  mes: number;
  dia: number;
  hora: number;
  minuto: number;
} {
  const ahoraUtc = new Date();

  const ecuador = new Date(
    ahoraUtc.getTime() -
      5 * 60 * 60 * 1000,
  );

  return {
    anio: ecuador.getUTCFullYear(),
    mes: ecuador.getUTCMonth() + 1,
    dia: ecuador.getUTCDate(),
    hora: ecuador.getUTCHours(),
    minuto: ecuador.getUTCMinutes(),
  };
}

// =========================================================
// CONSTRUIR FECHA SOLICITUD
// =========================================================
//
// El texto del usuario representa hora ECUADOR.
//
// Ejemplo:
//
// 17/09/2026 20:00 Ecuador
//
// se convierte internamente en:
//
// 18/09/2026 01:00 UTC
//
// Esto es lo que se almacena/compara en la base de datos.
// =========================================================

function construirFechaSolicitud(
  texto: string,
): Date | null {
  const hora = extraerHora(texto);

  if (!hora) {
    return null;
  }

  const ahoraEcuador =
    obtenerAhoraEcuador();

  let anio = ahoraEcuador.anio;
  let mes = ahoraEcuador.mes;
  let dia = ahoraEcuador.dia;

  // =======================================================
  // HOY
  // =======================================================

  if (/hoy/i.test(texto)) {
    // Se mantiene la fecha actual de Ecuador.
  }

  // =======================================================
  // MAÑANA
  // =======================================================

  if (/mañana/i.test(texto)) {
    const manana = new Date(
      Date.UTC(
        anio,
        mes - 1,
        dia + 1,
      ),
    );

    anio = manana.getUTCFullYear();
    mes = manana.getUTCMonth() + 1;
    dia = manana.getUTCDate();
  }

  // =======================================================
  // FECHA DD/MM/YYYY
  // DD-MM-YYYY
  // DD/MM
  // DD-MM
  // =======================================================

  const fechaMatch = texto.match(
    /\b(\d{1,2})[\/-](\d{1,2})(?:[\/-](\d{4}))?\b/,
  );

  if (fechaMatch) {
    dia = Number(fechaMatch[1]);
    mes = Number(fechaMatch[2]);

    if (fechaMatch[3]) {
      anio = Number(fechaMatch[3]);
    }
  }

  // =======================================================
  // VALIDAR FECHA
  // =======================================================

  if (
    mes < 1 ||
    mes > 12 ||
    dia < 1 ||
    dia > 31
  ) {
    console.log(
      "IA - FECHA INVÁLIDA:",
      `${dia}/${mes}/${anio}`,
    );

    return null;
  }

  // =======================================================
  // ECUADOR → UTC
  // =======================================================
  //
  // Ejemplo:
  //
  // Ecuador:
  // 17/09/2026 20:00
  //
  // UTC:
  // 18/09/2026 01:00
  // =======================================================

  const resultado = new Date(
    Date.UTC(
      anio,
      mes - 1,
      dia,
      hora.hora + 5,
      hora.minuto,
      0,
      0,
    ),
  );

  console.log("========================================");
  console.log("IA - CONSTRUCCIÓN DE FECHA");
  console.log("Texto:", texto);

  console.log(
    "Hora Ecuador detectada:",
    `${String(hora.hora).padStart(2, "0")}:${String(
      hora.minuto,
    ).padStart(2, "0")}`,
  );

  console.log(
    "Fecha Ecuador:",
    `${anio}-${String(mes).padStart(2, "0")}-${String(
      dia,
    ).padStart(2, "0")}`,
  );

  console.log(
    "UTC generado:",
    resultado.toISOString(),
  );

  console.log("========================================");

  return resultado;
}

// =========================================================
// NORMALIZAR AL MINUTO
// =========================================================

function normalizarMinuto(
  fecha: Date,
): Date {
  const resultado = new Date(fecha);

  resultado.setUTCSeconds(0, 0);

  return resultado;
}

// =========================================================
// FORMATEAR FECHA ECUADOR
// =========================================================

function formatearFechaEcuador(
  fecha: Date,
): string {
  const ecuador = new Date(
    fecha.getTime() -
      5 * 60 * 60 * 1000,
  );

  const dia = String(
    ecuador.getUTCDate(),
  ).padStart(2, "0");

  const mes = String(
    ecuador.getUTCMonth() + 1,
  ).padStart(2, "0");

  const anio =
    ecuador.getUTCFullYear();

  return `${dia}/${mes}/${anio}`;
}

// =========================================================
// FORMATEAR HORA ECUADOR
// =========================================================

function formatearHoraEcuador(
  fecha: Date,
): string {
  const ecuador = new Date(
    fecha.getTime() -
      5 * 60 * 60 * 1000,
  );

  const hora = String(
    ecuador.getUTCHours(),
  ).padStart(2, "0");

  const minuto = String(
    ecuador.getUTCMinutes(),
  ).padStart(2, "0");

  return `${hora}:${minuto}`;
}

// =========================================================
// FECHA YYYY-MM-DD ECUADOR
// =========================================================

function fechaIsoEcuador(
  fecha: Date,
): string {
  const ecuador = new Date(
    fecha.getTime() -
      5 * 60 * 60 * 1000,
  );

  const anio =
    ecuador.getUTCFullYear();

  const mes = String(
    ecuador.getUTCMonth() + 1,
  ).padStart(2, "0");

  const dia = String(
    ecuador.getUTCDate(),
  ).padStart(2, "0");

  return `${anio}-${mes}-${dia}`;
}

// =========================================================
// DISPONIBILIDAD REAL
// =========================================================

async function consultarDisponibilidad(
  fecha: Date,
) {
  const inicio =
    normalizarMinuto(fecha);

  const fin = new Date(inicio);

  fin.setUTCMinutes(
    fin.getUTCMinutes() + 1,
  );

  console.log("========================================");
  console.log("CONSULTA DE DISPONIBILIDAD");
  console.log(
    "Fecha recibida:",
    fecha.toISOString(),
  );
  console.log(
    "Inicio:",
    inicio.toISOString(),
  );
  console.log(
    "Fin:",
    fin.toISOString(),
  );
  console.log("========================================");

  const mesas =
    await prisma.mesa.findMany({
      where: {
        deletedAt: null,
        disponible: true,

        reservas: {
          none: {
            fecha: {
              gte: inicio,
              lt: fin,
            },

            estado: {
              in: [
                EstadoReserva.PENDIENTE,
                EstadoReserva.CONFIRMADA,
              ],
            },

            deletedAt: null,
          },
        },
      },

      orderBy: {
        id: "asc",
      },
    });

  console.log(
    "Mesas disponibles:",
    mesas.map(
      (mesa) =>
        `${mesa.id} - ${mesa.numero}`,
    ),
  );

  return mesas;
}

// =========================================================
// RESERVAS DEL USUARIO
// =========================================================

async function obtenerReservasUsuario(
  userId: number,
) {
  return prisma.reserva.findMany({
    where: {
      usuarioId: userId,
      deletedAt: null,
    },

    orderBy: {
      fecha: "desc",
    },

    take: 10,

    include: {
      mesa: true,
    },
  });
}

// =========================================================
// RESUMEN ADMIN
// =========================================================

async function obtenerResumenAdmin() {
  const [
    reservasPendientes,
    reservasConfirmadas,
    mesas,
  ] = await Promise.all([
    prisma.reserva.count({
      where: {
        estado:
          EstadoReserva.PENDIENTE,
        deletedAt: null,
      },
    }),

    prisma.reserva.count({
      where: {
        estado:
          EstadoReserva.CONFIRMADA,
        deletedAt: null,
      },
    }),

    prisma.mesa.count({
      where: {
        deletedAt: null,
      },
    }),
  ]);

  return {
    reservasPendientes,
    reservasConfirmadas,
    mesas,
  };
}

// =========================================================
// CHAT IA
// =========================================================

export async function chatAI(
  req: Request,
  res: Response,
) {
  try {
    // =======================================================
    // GEMINI
    // =======================================================

    if (!process.env.GEMINI_API_KEY) {
      return res.status(500).json({
        message:
          "La IA no está configurada en el servidor.",
      });
    }

    // =======================================================
    // MENSAJE
    // =======================================================

    const { message } = req.body;

    if (
      typeof message !== "string" ||
      !message.trim()
    ) {
      return res.status(422).json({
        message:
          "Debe enviar un mensaje.",
      });
    }

    if (message.length > 1000) {
      return res.status(422).json({
        message:
          "El mensaje es demasiado largo.",
      });
    }

    // =======================================================
    // USUARIO
    // =======================================================

    const role = getRole(req);
    const userId = getUserId(req);

    // =======================================================
    // DETECTAR DATOS
    // =======================================================

    const personas =
      extraerPersonas(message);

    const fechaSolicitud =
      construirFechaSolicitud(message);

    const esIntencionReserva =
      personas !== null &&
      fechaSolicitud !== null &&
      /(reservar|reserva|reservar una mesa|quiero una mesa|quiero reservar|agendar)/i.test(
        message,
      );

    // =======================================================
    // DISPONIBILIDAD
    // =======================================================

    let disponibilidadContext = "";

    let mesasDisponibles: any[] = [];

    if (fechaSolicitud) {
      mesasDisponibles =
        await consultarDisponibilidad(
          fechaSolicitud,
        );

      const fechaTexto =
        formatearFechaEcuador(
          fechaSolicitud,
        );

      const horaTexto =
        formatearHoraEcuador(
          fechaSolicitud,
        );

      disponibilidadContext = `
CONSULTA REAL DE DISPONIBILIDAD:

Fecha: ${fechaTexto}

Hora: ${horaTexto}

Cantidad real de mesas disponibles:
${mesasDisponibles.length}

Mesas disponibles:

${
  mesasDisponibles.length
    ? mesasDisponibles
        .map(
          (mesa) =>
            `- Mesa ${String(
              mesa.numero,
            )} (capacidad: ${
              mesa.capacidad
            })`,
        )
        .join("\n")
    : "- No hay mesas disponibles."
}

REGLA:

Utiliza exactamente esta información.

No inventes mesas.

No inventes capacidades.
`;
    }

    // =======================================================
    // CONTEXTO DE ROL
    // =======================================================

    let roleContext = "";

    if (isAdmin(role)) {
      const resumenAdmin =
        await obtenerResumenAdmin();

      roleContext = `
ROL DEL USUARIO: ADMINISTRADOR.

El administrador puede:

- Gestionar mesas.
- Crear mesas.
- Modificar mesas.
- Eliminar mesas.
- Consultar reservas.
- Confirmar reservas.
- Cancelar reservas.
- Consultar disponibilidad.
- Gestionar usuarios.
- Crear reservas para usuarios.

INFORMACIÓN ADMINISTRATIVA ACTUAL:

Reservas pendientes:
${resumenAdmin.reservasPendientes}

Reservas confirmadas:
${resumenAdmin.reservasConfirmadas}

Mesas registradas:
${resumenAdmin.mesas}
`;
    } else {
      roleContext = `
ROL DEL USUARIO: CLIENTE.

El cliente puede:

- Crear sus propias reservas.
- Consultar sus propias reservas.
- Consultar disponibilidad.
- Consultar el estado de sus reservas.
- Recibir ayuda sobre Leña Reserva.

El cliente NO puede:

- Gestionar mesas.
- Crear mesas.
- Modificar mesas.
- Eliminar mesas.
- Gestionar usuarios.
- Administrar reservas de otros usuarios.

Nunca muestres información privada de otros usuarios.
`;
    }

    // =======================================================
    // RESERVAS CLIENTE
    // =======================================================

    let reservasContext = "";

    if (
      userId !== null &&
      !isAdmin(role)
    ) {
      const reservas =
        await obtenerReservasUsuario(
          userId,
        );

      if (reservas.length > 0) {
        reservasContext = `
RESERVAS DEL CLIENTE AUTENTICADO:

${reservas
  .map((reserva) => {
    const fecha =
      formatearFechaEcuador(
        new Date(reserva.fecha),
      );

    const hora =
      formatearHoraEcuador(
        new Date(reserva.fecha),
      );

    return `- Reserva #${reserva.id}: ${fecha} a las ${hora}, personas: ${reserva.personas}, estado: ${reserva.estado}, mesa: ${
      reserva.mesa?.numero ??
      "sin mesa"
    }`;
  })
  .join("\n")}
`;
      } else {
        reservasContext = `
RESERVAS DEL CLIENTE AUTENTICADO:

No tiene reservas registradas.
`;
      }
    }

    // =======================================================
    // INSTRUCCIONES GEMINI
    // =======================================================

    const systemInstruction = `
Eres "Asistente Leña", el asistente virtual de la aplicación móvil "Leña Reserva".

Responde siempre en español.

FUNCIONES:

1. Ayudar a iniciar sesión.
2. Ayudar a registrar usuarios.
3. Ayudar con recuperación de contraseña.
4. Crear reservas mediante la pantalla Nueva Reserva.
5. Consultar reservas.
6. Consultar disponibilidad.
7. Consultar estados de reservas.
8. Ayudar con mesas si el usuario es ADMIN.
9. Ayudar con funciones administrativas si el usuario es ADMIN.

REGLAS:

- Sé claro y breve.
- No inventes información.
- No inventes disponibilidad.
- Utiliza los datos reales proporcionados por el backend.
- Nunca reveles datos privados de otros usuarios.
- Nunca muestres contraseñas.
- Nunca muestres tokens.
- Nunca muestres API keys.
- Nunca afirmes que una reserva fue creada si todavía no se creó.
- Nunca afirmes que una reserva fue cancelada si todavía no se canceló.
- No crees una reserva directamente desde Gemini.
- El usuario debe revisar la pantalla Nueva Reserva antes de crearla.

IMPORTANTE SOBRE HORARIOS:

Todos los horarios proporcionados por el usuario están expresados en hora de Ecuador continental (UTC-5).

Ejemplo:

"Quiero reservar mañana a las 20:00"

significa:

20:00 hora de Ecuador.

Nunca conviertas 20:00 a 04:00.

INTENCIÓN DE RESERVA:

Si el usuario dice:

"Quiero reservar una mesa para 4 personas mañana a las 20:00."

debes reconocer que quiere crear una reserva.

El backend proporciona los datos detectados.

La aplicación abrirá la pantalla Nueva Reserva.

No selecciones una mesa por tu cuenta.

DISPONIBILIDAD:

Cuando exista información real de disponibilidad:

- Usa exactamente la cantidad recibida.
- Usa únicamente las mesas recibidas.
- No inventes mesas.
- No inventes capacidades.

ROLES:

${roleContext}

${reservasContext}

${disponibilidadContext}
`;

    // =======================================================
    // GEMINI
    // =======================================================

    const response =
      await ai.models.generateContent({
        model: MODEL,

        contents: message.trim(),

        config: {
          systemInstruction,

          temperature: 0.2,

          maxOutputTokens: 500,
        },
      });

    const answer =
      response.text?.trim() ||
      "No pude generar una respuesta en este momento.";

    // =======================================================
    // BORRADOR DE RESERVA
    // =======================================================

    let reservationDraft:
      | {
          people: number;
          date: string;
          time: string;
        }
      | null = null;

    if (
      esIntencionReserva &&
      personas !== null &&
      fechaSolicitud !== null
    ) {
      reservationDraft = {
        people: personas,

        date: fechaIsoEcuador(
          fechaSolicitud,
        ),

        time: formatearHoraEcuador(
          fechaSolicitud,
        ),
      };

      console.log(
        "========================================",
      );

      console.log(
        "AI - RESERVATION DRAFT BACKEND",
      );

      console.log(
        "Mensaje:",
        message,
      );

      console.log(
        "Personas:",
        personas,
      );

      console.log(
        "Fecha Ecuador:",
        fechaIsoEcuador(
          fechaSolicitud,
        ),
      );

      console.log(
        "Hora Ecuador:",
        formatearHoraEcuador(
          fechaSolicitud,
        ),
      );

      console.log(
        "Fecha UTC:",
        fechaSolicitud.toISOString(),
      );

      console.log(
        "Draft:",
        reservationDraft,
      );

      console.log(
        "========================================",
      );
    }

    // =======================================================
    // RESPUESTA
    // =======================================================

    return res.status(200).json({
      answer,

      role,

      availability: fechaSolicitud
        ? {
            fecha:
              fechaSolicitud.toISOString(),

            cantidad:
              mesasDisponibles.length,

            mesas:
              mesasDisponibles.map(
                (mesa) => ({
                  id: mesa.id,

                  numero:
                    mesa.numero,

                  capacidad:
                    mesa.capacidad,
                }),
              ),
          }
        : null,

      reservationDraft,
    });
  } catch (error) {
    console.error(
      "Error en Asistente Leña:",
      error,
    );

    return res.status(500).json({
      message:
        "No fue posible comunicarse con el asistente.",
    });
  }
}