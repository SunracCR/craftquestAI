# Verificación de dominio (Sign in with Apple web)

Apple exige un archivo de verificación en esta ruta:

```
https://app.craftquestai.com/.well-known/apple-developer-domain-association.txt
```

## Cómo obtenerlo

1. [Apple Developer](https://developer.apple.com/account) → **Identifiers** → **Services IDs** → `com.craftquestai.web`.
2. **Sign in with Apple** → **Configure** → dominio `app.craftquestai.com`.
3. Apple ofrece **Download** del archivo de verificación.
4. Guarda el contenido en este directorio como:

   `apple-developer-domain-association.txt`

5. Despliega la web (Azure Static Web Apps).
6. Comprueba que la URL devuelve el archivo (no el HTML de Flutter):

   ```bash
   curl https://app.craftquestai.com/.well-known/apple-developer-domain-association.txt
   ```

7. En Apple Developer, pulsa **Verify** junto al dominio.

Sin dominio verificado, Apple responde `invalid_request` / **Invalid web redirect url** aunque el Return URL esté bien registrado.
