import nodemailer from "nodemailer";

const smtpPort = Number(process.env.SMTP_PORT ?? 587);

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: smtpPort,
  secure: smtpPort === 465,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

export async function sendPasswordResetEmail(
  correo: string,
  nombre: string,
  codigo: string
) {
  await transporter.sendMail({
    from: process.env.SMTP_FROM,
    to: correo,
    subject: "Recuperación de contraseña - Leña Reserva",
    text: `Hola ${nombre},

Recibimos una solicitud para recuperar tu contraseña de Leña Reserva.

Tu código de recuperación es:

${codigo}

Este código es válido durante 10 minutos y solo puede utilizarse una vez.

Si no solicitaste este cambio, puedes ignorar este correo.

Leña Reserva`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto;">
        <h2>Leña Reserva</h2>

        <p>Hola <strong>${nombre}</strong>,</p>

        <p>
          Recibimos una solicitud para recuperar tu contraseña.
        </p>

        <div style="
          padding: 20px;
          text-align: center;
          background: #f5f2f0;
          border-radius: 10px;
          margin: 20px 0;
        ">
          <p style="margin: 0 0 8px;">Tu código de recuperación es:</p>

          <div style="
            font-size: 32px;
            font-weight: bold;
            letter-spacing: 8px;
          ">
            ${codigo}
          </div>
        </div>

        <p>
          El código es válido durante <strong>10 minutos</strong>
          y solo puede utilizarse una vez.
        </p>

        <p>
          Si no solicitaste recuperar tu contraseña,
          puedes ignorar este correo.
        </p>

        <p>Leña Reserva</p>
      </div>
    `,
  });
}