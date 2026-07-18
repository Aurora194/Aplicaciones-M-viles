import jwt from "jsonwebtoken";

const SECRET = process.env.JWT_SECRET || "lena_reserva_secret";

export function generateAccessToken(user: any): string {
    return jwt.sign(
        {
            id: user.id,
            correo: user.correo,
            rol: user.rol
        },
        SECRET,
        {
            expiresIn: "1h"
        }
    );
}

export function verifyToken(token: string) {
    return jwt.verify(token, SECRET);
}