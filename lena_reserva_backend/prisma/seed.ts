import bcrypt from "bcryptjs";
import { EstadoReserva, PrismaClient, Rol } from "@prisma/client";

const prisma = new PrismaClient();

async function main() {
  const password = await bcrypt.hash("123456", 10);
  const admin = await prisma.usuario.upsert({
    where: { correo: "admin@gmail.com" },
    update: { nombre: "Administrador", apellido: "Leña", telefono: "3000000000", password, rol: Rol.ADMIN, deletedAt: null },
    create: { nombre: "Administrador", apellido: "Leña", correo: "admin@gmail.com", telefono: "3000000000", password, rol: Rol.ADMIN },
  });
  for (const table of [
    { numero: 1, capacidad: 2 },
    { numero: 2, capacidad: 4 },
    { numero: 3, capacidad: 4 },
    { numero: 4, capacidad: 6 },
    { numero: 5, capacidad: 6 },
    { numero: 6, capacidad: 8 },
  ]) {
    await prisma.mesa.upsert({
      where: { numero: table.numero },
      update: { capacidad: table.capacidad, disponible: true, deletedAt: null },
      create: { ...table, disponible: true },
    });
  }

  const tables = await prisma.mesa.findMany({
    where: { numero: { in: [1, 2, 3] } },
    orderBy: { numero: "asc" },
  });
  if (tables.length === 3) {
    const examples = [
      { fecha: new Date("2026-09-10T19:30:00.000Z"), personas: 4, estado: EstadoReserva.CONFIRMADA, mesaId: tables[0].id },
      { fecha: new Date("2026-09-12T21:00:00.000Z"), personas: 2, estado: EstadoReserva.PENDIENTE, mesaId: tables[1].id },
      { fecha: new Date("2026-09-14T18:15:00.000Z"), personas: 6, estado: EstadoReserva.CANCELADA, mesaId: tables[2].id },
    ];

    for (const example of examples) {
      const existing = await prisma.reserva.findFirst({
        where: { usuarioId: admin.id, mesaId: example.mesaId, fecha: example.fecha },
      });
      if (existing) {
        await prisma.reserva.update({
          where: { id: existing.id },
          data: { personas: example.personas, estado: example.estado, deletedAt: null },
        });
      } else {
        await prisma.reserva.create({ data: { ...example, usuarioId: admin.id } });
      }
    }
  }
}

main()
  .catch((error) => {
    console.error("No se pudieron crear las mesas iniciales:", error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
