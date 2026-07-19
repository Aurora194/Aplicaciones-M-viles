import jwt, { Secret, SignOptions } from "jsonwebtoken";


const ACCESS_SECRET: Secret =
process.env.JWT_SECRET || "lena_reserva_secret";


const REFRESH_SECRET: Secret =
process.env.REFRESH_SECRET || "lena_refresh_secret";


const ACCESS_EXPIRES =
(process.env.JWT_EXPIRES_IN || "1h") as SignOptions["expiresIn"];


const REFRESH_EXPIRES =
(process.env.REFRESH_TOKEN_EXPIRES || "7d") as SignOptions["expiresIn"];



export function generateAccessToken(usuario:any){

    return jwt.sign(
        {
            id: usuario.id,
            correo: usuario.correo,
            rol: usuario.rol
        },
        ACCESS_SECRET,
        {
            expiresIn: ACCESS_EXPIRES
        }
    );

}



export function generateRefreshToken(usuario:any){

    return jwt.sign(
        {
            id: usuario.id
        },
        REFRESH_SECRET,
        {
            expiresIn: REFRESH_EXPIRES
        }
    );

}



export function verifyRefreshToken(token:string){

    return jwt.verify(
        token,
        REFRESH_SECRET
    );

}