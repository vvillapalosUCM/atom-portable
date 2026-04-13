# Auditoria de seguridad - atom-portable-asistente-ia

**Fecha:** 13 de abril de 2026

## Resumen

12 vulnerabilidades identificadas y corregidas (2 criticas, 5 altas, 3 medias, 2 bajas).

### CRITICAS

**C1. Credenciales hardcoded y commiteadas** - `.env` con contrasenas reales commiteado al repo. Healthcheck de MySQL con contrasena root visible en `docker inspect`.
*Fix:* `.env` eliminado, `.env.example` con placeholder, `.gitignore` actualizado, script genera contrasenas aleatorias, healthcheck sin contrasena.

**C2. Contrasena root MySQL en linea de comandos del healthcheck** - Visible en proceso.
*Fix:* `mysqladmin ping -h localhost` sin contrasena.

### ALTAS

**A1. Puertos expuestos a toda la red** - 8080 y 8081 en 0.0.0.0.
*Fix:* Binding a 127.0.0.1.

**A2. Sin cabeceras de seguridad en nginx** - Sin X-Frame-Options, CSP, etc.
*Fix:* Cabeceras anadidas, server_tokens off.

**A3. URL de Ollama sin validacion** - localStorage podia redirigir texto a servidor externo.
*Fix:* Solo acepta localhost/127.0.0.1.

**A4. Sin limite de texto en asistente IA** - Sin maxlength.
*Fix:* 100.000 caracteres maximo.

**A5. Sin CSP en asistente IA** - Sin Content-Security-Policy.
*Fix:* Meta tag CSP restrictivo.

### MEDIAS

**M1. atom_worker sin volumen uploads** - No podia procesar archivos subidos.
*Fix:* Volumen anadido.

**M2. Sin documentacion de seguridad** - No existia informe.
*Fix:* Este documento.

**M3. Docker images por tag, no digest** - Riesgo de supply chain.
*Nota:* Aceptable para formacion.

### BAJAS

**B1. Google Fonts en INSTRUCCIONES.html** - Peticion externa.
**B2. Contrasena admin visible en pantalla** - Intencionado para formacion.
