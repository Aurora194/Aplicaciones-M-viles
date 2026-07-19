import prisma from "../config/prisma";

export async function saveRefreshToken(
    usuarioId: number,
    token: string,
    expiresAt: Date
) {
    return prisma.refreshToken.create({
        data: {
            usuarioId,
            token,
            expiresAt
        }
    });
}

export async function findRefreshToken(token: string) {
    return prisma.refreshToken.findUnique({
        where: {
            token
        }
    });
}

export async function deleteRefreshToken(token: string) {
    return prisma.refreshToken.delete({
        where: {
            token
        }
    });
}

export async function deleteAllUserTokens(usuarioId: number) {
    return prisma.refreshToken.deleteMany({
        where: {
            usuarioId
        }
    });
}