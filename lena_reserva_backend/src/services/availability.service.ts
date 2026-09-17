import prisma from "../config/prisma";

export async function consultarDisponibilidad(fecha: Date) {
  const inicio = new Date(fecha);

  // Normalizar al inicio del minuto
  inicio.setUTCSeconds(0, 0);

  // El rango de búsqueda corresponde a un minuto
  const fin = new Date(inicio);
  fin.setUTCMinutes(fin.getUTCMinutes() + 1);

  console.log("======================================");
  console.log("CONSULTA DE DISPONIBILIDAD");
  console.log("Fecha recibida:", fecha.toISOString());
  console.log("Inicio:", inicio.toISOString());
  console.log("Fin:", fin.toISOString());

  const mesas = await prisma.mesa.findMany({
    where: {
      deletedAt: null,
      disponible: true,

      reservas: {
        none: {
          estado: {
            in: ["PENDIENTE", "CONFIRMADA"],
          },

          fecha: {
            gte: inicio,
            lt: fin,
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
    mesas.map((mesa) => `${mesa.numero}`)
  );

  return mesas;
}

