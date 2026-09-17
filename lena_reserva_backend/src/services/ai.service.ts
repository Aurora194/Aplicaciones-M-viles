import { GoogleGenAI } from "@google/genai";

const apiKey = process.env.GEMINI_API_KEY;

if (!apiKey) {
  console.warn("GEMINI_API_KEY no está configurada.");
}

const ai = new GoogleGenAI({
  apiKey,
});

export async function askLeñaAI(message: string): Promise<string> {
  const prompt = `
Eres el asistente virtual de la aplicación "Leña Reserva".

Tu función es ayudar a los usuarios a utilizar la aplicación de
reservas de restaurante.

Puedes explicar:
- cómo crear una reserva;
- cómo consultar disponibilidad;
- cómo editar una reserva;
- cómo cancelar una reserva;
- qué significan los estados pendiente, confirmada y cancelada;
- cómo consultar las reservas;
- cómo utilizar las funciones principales de la aplicación.

Reglas:
- Responde siempre en español.
- Sé claro y breve.
- No inventes funciones que la aplicación no tenga.
- No inventes horarios, mesas o reservas.
- Si el usuario pregunta algo que no corresponde a Leña Reserva,
  indica amablemente que puedes ayudar con el funcionamiento
  de la aplicación.

Pregunta del usuario:
${message}
`;

  const response = await ai.models.generateContent({
    model: "gemini-2.5-flash-lite",
    contents: prompt,
  });

  return response.text?.trim() ||
      "No pude generar una respuesta en este momento.";
}