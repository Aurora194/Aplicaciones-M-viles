import jwt, { Secret, SignOptions } from "jsonwebtoken";

const SECRET: Secret =
    process.env.JWT_SECRET || "lena_reserva_secret";

const EXPIRES_IN =
    (process.env.REFRESH_TOKEN_EXPIRES || "7d") as SignOptions["expiresIn"];

export function generateRefreshToken(usuarioId: number): string {

    return jwt.sign(

        {
            id: usuarioId
        },

        SECRET,

        {
            expiresIn: EXPIRES_IN
        }

    );

}

export function verifyRefreshToken(token: string): any {

    return jwt.verify(token, SECRET);

}