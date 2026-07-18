import { z } from "zod";

export const updateUserSchema = z.object({

    nombre: z.string().min(3).max(50),

    apellido: z.string().min(3).max(50),

    telefono: z.string().min(7).max(15)

});

export type UpdateUserDTO = z.infer<typeof updateUserSchema>;