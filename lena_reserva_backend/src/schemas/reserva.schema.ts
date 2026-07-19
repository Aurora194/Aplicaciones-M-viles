import { z } from "zod";

export const reservaSchema = z.object({
  fecha: z.string().transform((v) => new Date(v)),
  personas: z.number().int().positive(),
  usuarioId: z.number().int().positive(),
  mesaId: z.number().int().positive(),
  estado: z.enum(["PENDIENTE", "CONFIRMADA", "CANCELADA"]).optional()
});

export const updateReservaSchema = reservaSchema.partial();