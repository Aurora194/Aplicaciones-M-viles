import { z } from "zod";

export const reservaSchema = z.object({

    fecha: z.string().datetime(),

    personas: z.number().int().min(1).max(20),

    usuarioId: z.number().int().positive(),

    mesaId: z.number().int().positive()

});

export type ReservaDTO = z.infer<typeof reservaSchema>;