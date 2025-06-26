# NEWAGEFrntEUI

This project uses ESLint for code quality checks.

## Setup

Before running `npm run lint`, install the required dependencies with the setup script:

```bash
./scripts/setup.sh
```

After setup you can lint the project:

```bash
npm run lint
```
If `npm run lint` fails due to missing packages, run `./scripts/setup.sh` again to reinstall them.

The dev dependencies include `@eslint/js` and related packages configured in `eslint.config.js`.

## Environment Variables

Copy `.env.example` to `.env` and fill in your Supabase credentials:

```bash
cp .env.example .env
```

The `.env` file is excluded from version control.

## Tests

No automated tests are currently available.
# trigger deploy
