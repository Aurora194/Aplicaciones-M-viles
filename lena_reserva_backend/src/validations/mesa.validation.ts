import { z } from "zod";

export const mesaSchema = z.object({

    numero: z.number().int().positive(),

    capacidad: z.number().int().min(1).max(20),

    disponible: z.boolean().optional()

});

export type MesaDTO = z.infer<typeof mesaSchema>;