#!/usr/bin/env node
/**
 * Мок-сервер учебного API «Библиотека».
 *
 * Реализует контракт из файла КОНТРАКТ-API.md.
 * Зависимостей нет — нужен только Node.js 18 или новее.
 *
 *   node mock-server.js
 *   node mock-server.js --port 8080 --origin http://localhost:5555
 *
 * Данные хранятся в памяти и сбрасываются при перезапуске
 * либо запросом POST /api/__reset
 *
 * Учебные возможности:
 *   ?__delay=1500   задержка ответа в миллисекундах (проверка индикатора загрузки)
 *   ?__fail=500     принудительный код ошибки (проверка обработки ошибок)
 */

'use strict';

const http = require('node:http');
const crypto = require('node:crypto');

// ─────────────────────────── параметры запуска ───────────────────────────

const args = process.argv.slice(2);
function arg(name, fallback) {
  const i = args.indexOf('--' + name);
  return i !== -1 && args[i + 1] ? args[i + 1] : fallback;
}

const PORT = Number(arg('port', 8080));
const ORIGIN = arg('origin', '*');
const SECRET = 'учебный-ключ-не-для-продакшена';
const ACCESS_TTL = Number(arg('ttl', 900));      // секунд
const REFRESH_TTL = 60 * 60 * 24 * 7;

// ─────────────────────────────── токены ───────────────────────────────

function b64url(buf) {
  return Buffer.from(buf).toString('base64url');
}

function sign(payload) {
  // jti делает каждый токен уникальным. Без него два токена, выпущенных
  // в одну и ту же секунду для одного пользователя, совпадут побайтово,
  // и отзыв старого токена обновления отзовёт заодно и новый.
  const withId = { ...payload, jti: crypto.randomUUID() };
  const body = b64url(JSON.stringify(withId));
  const mac = crypto.createHmac('sha256', SECRET).update(body).digest('base64url');
  return body + '.' + mac;
}

function verify(token) {
  if (typeof token !== 'string' || !token.includes('.')) return null;
  const [body, mac] = token.split('.');
  const expected = crypto.createHmac('sha256', SECRET).update(body).digest('base64url');
  if (mac !== expected) return null;
  let payload;
  try {
    payload = JSON.parse(Buffer.from(body, 'base64url').toString('utf8'));
  } catch {
    return null;
  }
  if (payload.exp && payload.exp * 1000 < Date.now()) return null;
  return payload;
}

// ─────────────────────────────── данные ───────────────────────────────

let db;

function seed() {
    db = {
      seq: {},
      publishers: [],
      authors: [],
      genres: [],
      books: [],
      readers: [],
      cards: [],
      loans: [],
      users: [],
      refreshTokens: new Set(),
    };

    const P = (name, city, foundedYear) => push('publishers', { name, city, foundedYear });
    const A = (fullName, birthYear, country) => push('authors', { fullName, birthYear, country });
    const G = (name, description) => push('genres', { name, description });

    const p1 = P('АСТ', 'Москва', 1990);
const p2 = P('Эксмо', 'Москва', 1991);
const p3 = P('Азбука', 'Санкт-Петербург', 1995);
const p4 = P('Питер', 'Санкт-Петербург', 1991);
const p5 = P('Просвещение', 'Москва', 1930);
const p6 = P('Альпина', 'Москва', 1998);

    const a1 = A('Булгаков Михаил', 1891, 'Россия'); const a2 = A('Достоевский Фёдор', 1821, 'Россия'); const a3 = A('Толстой Лев', 1828, 'Россия'); const a4 = A('Гоголь Николай', 1809, 'Россия'); const a5 = A('Лермонтов Михаил', 1814, 'Россия'); const a6 = A('Тургенев Иван', 1818, 'Россия'); const a7 = A('Пастернак Борис', 1890, 'Россия'); const a8 = A('Ильф Илья', 1897, 'Россия');

    const g1 = G('Роман', 'Роман и крупная проза'); const g2 = G('Комедия', 'Комедийные и сатирические произведения'); const g3 = G('Поэзия', 'Поэтические и лиро-эпические произведения'); const g4 = G('Фантастика', 'Фантастическая литература');

    const B = (title, isbn, year, pages, publisherId, authorIds, genreIds, copiesTotal) =>
      push('books', {
        title, isbn, year, pages, publisherId, authorIds, genreIds,
        copiesTotal, copiesAvailable: copiesTotal,
      });

    const b1 = B('Мастер и Маргарита', '9785171187564', 1967, 480, p1, [a1], [g1,g2], 10); db.books.find((x) => x.id === b1).copiesAvailable = 7; const b2 = B('Преступление и наказание', '9785170904191', 1866, 672, p1, [a2], [g1], 8); db.books.find((x) => x.id === b2).copiesAvailable = 5; const b3 = B('Война и мир', '9785170904207', 1869, 1225, p2, [a3], [g1,g3], 12); db.books.find((x) => x.id === b3).copiesAvailable = 4; const b4 = B('Анна Каренина', '9785170904214', 1878, 864, p2, [a3], [g1], 9); db.books.find((x) => x.id === b4).copiesAvailable = 6; const b5 = B('Евгений Онегин', '9785170904221', 1833, 384, p3, [a4], [g2,g3], 7); db.books.find((x) => x.id === b5).copiesAvailable = 3; const b6 = B('Герой нашего времени', '9785170904238', 1840, 224, p3, [a5], [g1,g2], 6); db.books.find((x) => x.id === b6).copiesAvailable = 5; const b7 = B('Отцы и дети', '9785170904245', 1862, 288, p4, [a6], [g1], 8); db.books.find((x) => x.id === b7).copiesAvailable = 2; const b8 = B('Доктор Живаго', '9785170904252', 1957, 704, p4, [a7], [g1,g3], 10); db.books.find((x) => x.id === b8).copiesAvailable = 8; const b9 = B('Тихий Дон', '9785170904269', 1928, 1056, p5, [a8], [g1,g3], 11); db.books.find((x) => x.id === b9).copiesAvailable = 6; const b10 = B('Мы', '9785170904276', 1924, 288, p5, [a1], [g4], 6); db.books.find((x) => x.id === b10).copiesAvailable = 4; const b11 = B('Пикник на обочине', '9785170904283', 1972, 256, p6, [a2], [g4], 9); db.books.find((x) => x.id === b11).copiesAvailable = 7; const b12 = B('Собачье сердце', '9785170904290', 1925, 192, p6, [a1], [g2], 7); db.books.find((x) => x.id === b12).copiesAvailable = 5; const b13 = B('Идиот', '9785170904306', 1869, 640, p1, [a2], [g1], 10); db.books.find((x) => x.id === b13).copiesAvailable = 6; const b14 = B('Братья Карамазовы', '9785170904313', 1880, 960, p2, [a2], [g1], 10); db.books.find((x) => x.id === b14).copiesAvailable = 3; const b15 = B('Мёртвые души', '9785170904320', 1842, 352, p3, [a4], [g1,g2], 8); db.books.find((x) => x.id === b15).copiesAvailable = 5; const b16 = B('Ревизор', '9785170904337', 1836, 160, p3, [a4], [g2], 5); db.books.find((x) => x.id === b16).copiesAvailable = 4; const b17 = B('Обломов', '9785170904344', 1859, 480, p4, [a6], [g1,g2], 7); db.books.find((x) => x.id === b17).copiesAvailable = 2; const b18 = B('Лолита', '9785170904351', 1955, 368, p5, [a7], [g1], 6); db.books.find((x) => x.id === b18).copiesAvailable = 3; const b19 = B('Золотой телёнок', '9785170904368', 1931, 352, p6, [a8], [g2], 8); db.books.find((x) => x.id === b19).copiesAvailable = 6; const b20 = B('Двенадцать стульев', '9785170904375', 1928, 416, p6, [a8], [g2], 9); db.books.find((x) => x.id === b20).copiesAvailable = 7;

    const readerNames = [
      ['Смирнов П. А.', 'smirnov@example.com', '+7 900 100-10-01'],
      ['Кузнецова М. И.', 'kuznetsova@example.com', '+7 900 100-10-02'],
      ['Попов Д. С.', 'popov@example.com', '+7 900 100-10-03'],
      ['Васильева Е. О.', 'vasileva@example.com', '+7 900 100-10-04'],
      ['Новиков А. В.', 'novikov@example.com', '+7 900 100-10-05'],
      ['Морозова Т. Н.', 'morozova@example.com', '+7 900 100-10-06'],
    ];

    readerNames.forEach(([fullName, email, phone], i) => {
      const readerId = push('readers', { fullName, email, phone });
      push('cards', {
        readerId,
        number: 'RC-' + String(readerId).padStart(6, '0'),
        issuedAt: iso(2026, 1, 15 + i),
        expiresAt: iso(2027, 1, 15 + i),
      });
    });

    makeLoan(1, 1, -20, 14);
    makeLoan(2, 6, -5, 14);
    makeLoan(3, 11, -30, 14, true);

    push('users', { username: 'admin', passwordHash: hash('admin123'), fullName: 'Администратор', email: 'admin@library.local', role: 'admin', readerId: null });
    push('users', { username: 'librarian', passwordHash: hash('librarian123'), fullName: 'Петрова А. С.', email: 'petrova@library.local', role: 'librarian', readerId: null });
    push('users', { username: 'reader', passwordHash: hash('reader123'), fullName: 'Смирнов П. А.', email: 'smirnov@example.com', role: 'reader', readerId: 1 });
  }
function push(collection, obj) {
  db.seq[collection] = (db.seq[collection] || 0) + 1;
  const id = db.seq[collection];
  db[collection].push({ id, ...obj, createdAt: new Date().toISOString(), deletedAt: null });
  return id;
}

function iso(y, m, d) {
  return new Date(Date.UTC(y, m - 1, d)).toISOString();
}

function hash(password) {
  return crypto.createHash('sha256').update(password + SECRET).digest('hex');
}

function makeLoan(readerId, bookId, issuedDaysAgo, days, returned = false) {
  const issuedAt = new Date(Date.now() + issuedDaysAgo * 86400000);
  const dueAt = new Date(issuedAt.getTime() + days * 86400000);
  const id = push('loans', {
    readerId,
    bookId,
    issuedAt: issuedAt.toISOString(),
    dueAt: dueAt.toISOString(),
    returnedAt: returned ? new Date().toISOString() : null,
  });
  if (!returned) {
    const book = db.books.find((b) => b.id === bookId);
    if (book) book.copiesAvailable = Math.max(0, book.copiesAvailable - 1);
  }
  return id;
}

// ──────────────────────── развёртывание объектов ────────────────────────

function slimPublisher(id) {
  const p = db.publishers.find((x) => x.id === id);
  return p ? { id: p.id, name: p.name } : null;
}

function expandBook(b) {
  return {
    id: b.id,
    title: b.title,
    isbn: b.isbn,
    year: b.year,
    pages: b.pages,
    publisher: slimPublisher(b.publisherId),
    authors: b.authorIds
      .map((id) => db.authors.find((a) => a.id === id))
      .filter(Boolean)
      .map((a) => ({ id: a.id, fullName: a.fullName })),
    genres: b.genreIds
      .map((id) => db.genres.find((g) => g.id === id))
      .filter(Boolean)
      .map((g) => ({ id: g.id, name: g.name })),
    copiesTotal: b.copiesTotal,
    copiesAvailable: b.copiesAvailable,
    createdAt: b.createdAt,
    deletedAt: b.deletedAt,
  };
}

function expandReader(r) {
  const card = db.cards.find((c) => c.readerId === r.id && !c.deletedAt);
  return {
    id: r.id,
    fullName: r.fullName,
    email: r.email,
    phone: r.phone,
    card: card
      ? { id: card.id, number: card.number, issuedAt: card.issuedAt, expiresAt: card.expiresAt }
      : null,
    createdAt: r.createdAt,
    deletedAt: r.deletedAt,
  };
}

function expandLoan(l) {
  const reader = db.readers.find((r) => r.id === l.readerId);
  const book = db.books.find((b) => b.id === l.bookId);
  let status = 'active';
  if (l.returnedAt) status = 'returned';
  else if (new Date(l.dueAt) < new Date()) status = 'overdue';
  return {
    id: l.id,
    reader: reader ? { id: reader.id, fullName: reader.fullName } : null,
    book: book ? { id: book.id, title: book.title } : null,
    issuedAt: l.issuedAt,
    dueAt: l.dueAt,
    returnedAt: l.returnedAt,
    status,
    deletedAt: l.deletedAt,
  };
}

function expandUser(u) {
  return { id: u.id, username: u.username, fullName: u.fullName, email: u.email, role: u.role, readerId: u.readerId };
}

const EXPANDERS = {
  books: expandBook,
  readers: expandReader,
  loans: expandLoan,
  authors: (a) => a,
  genres: (g) => g,
  publishers: (p) => p,
};

// ─────────────────────────── общие операции ───────────────────────────

function searchableText(collection, item) {
  switch (collection) {
    case 'books': return [item.title, item.isbn].join(' ');
    case 'authors': return [item.fullName, item.country].join(' ');
    case 'genres': return [item.name, item.description].join(' ');
    case 'publishers': return [item.name, item.city].join(' ');
    case 'readers': return [item.fullName, item.email, item.phone].join(' ');
    default: return '';
  }
}

function applyFilters(collection, rows, q) {
  let result = rows;

  if (q.search) {
    const needle = String(q.search).toLowerCase();
    result = result.filter((x) => searchableText(collection, x).toLowerCase().includes(needle));
  }

  if (collection === 'books') {
    if (q.genreId) result = result.filter((b) => b.genreIds.includes(Number(q.genreId)));
    if (q.authorId) result = result.filter((b) => b.authorIds.includes(Number(q.authorId)));
    if (q.publisherId) result = result.filter((b) => b.publisherId === Number(q.publisherId));
    if (q.yearFrom) result = result.filter((b) => b.year >= Number(q.yearFrom));
    if (q.yearTo) result = result.filter((b) => b.year <= Number(q.yearTo));
    if (q.available === 'true') result = result.filter((b) => b.copiesAvailable > 0);
  }

  if (collection === 'loans') {
    if (q.readerId) result = result.filter((l) => l.readerId === Number(q.readerId));
    if (q.bookId) result = result.filter((l) => l.bookId === Number(q.bookId));
    if (q.status) {
      result = result.filter((l) => expandLoan(l).status === q.status);
    }
  }

  return result;
}

function applySort(rows, sort) {
  if (!sort) return rows;
  const [field, dirRaw] = String(sort).split(',');
  const dir = (dirRaw || 'asc').toLowerCase() === 'desc' ? -1 : 1;
  return [...rows].sort((a, b) => {
    const av = a[field];
    const bv = b[field];
    if (av == null && bv == null) return 0;
    if (av == null) return 1;
    if (bv == null) return -1;
    if (typeof av === 'number' && typeof bv === 'number') return (av - bv) * dir;
    return String(av).localeCompare(String(bv), 'ru') * dir;
  });
}

function paginate(rows, q) {
  const page = Math.max(1, Number(q.page) || 1);
  const size = Math.min(100, Math.max(1, Number(q.size) || 10));
  const total = rows.length;
  const totalPages = Math.max(1, Math.ceil(total / size));
  return {
    items: rows.slice((page - 1) * size, page * size),
    page,
    size,
    total,
    totalPages,
  };
}

// ─────────────────────────────── валидация ───────────────────────────────

function validate(collection, body, id = null) {
  const e = {};
  const str = (v) => (typeof v === 'string' ? v.trim() : '');

  if (collection === 'books') {
    if (!str(body.title)) e.title = 'Укажите название';
    else if (str(body.title).length > 200) e.title = 'Не длиннее 200 символов';

    if (!str(body.isbn)) e.isbn = 'Укажите ISBN';
    else {
      const dup = db.books.find((b) => b.isbn === str(body.isbn) && b.id !== id && !b.deletedAt);
      if (dup) e.isbn = 'Книга с таким ISBN уже существует';
    }

    const year = Number(body.year);
    if (!Number.isInteger(year)) e.year = 'Год — целое число';
    else if (year < 1450) e.year = 'Год не может быть раньше 1450';
    else if (year > new Date().getFullYear()) e.year = 'Год не может быть в будущем';

    if (body.pages != null && (!Number.isInteger(Number(body.pages)) || Number(body.pages) < 1)) {
      e.pages = 'Число страниц — положительное целое';
    }
    if (body.publisherId != null && !db.publishers.find((p) => p.id === Number(body.publisherId) && !p.deletedAt)) {
      e.publisherId = 'Издательство не найдено';
    }
    const copies = Number(body.copiesTotal);
    if (!Number.isInteger(copies) || copies < 0) e.copiesTotal = 'Число экземпляров — целое, не меньше нуля';
  }

  if (collection === 'authors') {
    if (!str(body.fullName)) e.fullName = 'Укажите имя автора';
    if (body.birthYear != null) {
      const y = Number(body.birthYear);
      if (!Number.isInteger(y) || y < 1 || y > new Date().getFullYear()) e.birthYear = 'Некорректный год рождения';
    }
  }

  if (collection === 'genres') {
    if (!str(body.name)) e.name = 'Укажите название жанра';
    else {
      const dup = db.genres.find((g) => g.name.toLowerCase() === str(body.name).toLowerCase() && g.id !== id && !g.deletedAt);
      if (dup) e.name = 'Такой жанр уже существует';
    }
  }

  if (collection === 'publishers') {
    if (!str(body.name)) e.name = 'Укажите название издательства';
    if (body.foundedYear != null) {
      const y = Number(body.foundedYear);
      if (!Number.isInteger(y) || y < 1400 || y > new Date().getFullYear()) e.foundedYear = 'Некорректный год основания';
    }
  }

  if (collection === 'readers') {
    if (!str(body.fullName)) e.fullName = 'Укажите ФИО читателя';
    if (!str(body.email)) e.email = 'Укажите адрес почты';
    else if (!/^[\w.+-]+@[\w-]+\.[\w.-]+$/.test(str(body.email))) e.email = 'Некорректный адрес почты';
    else {
      const dup = db.readers.find((r) => r.email === str(body.email) && r.id !== id && !r.deletedAt);
      if (dup) e.email = 'Читатель с такой почтой уже зарегистрирован';
    }
  }

  return e;
}


// ──────────────────────────── HTTP-обвязка ────────────────────────────

function cors(res) {
  res.setHeader('Access-Control-Allow-Origin', ORIGIN);
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Access-Control-Max-Age', '86400');
  res.setHeader('Vary', 'Origin');
}

function send(res, status, payload) {
  cors(res);
  if (payload === undefined || status === 204) {
    res.writeHead(204);
    res.end();
    return;
  }
  const body = JSON.stringify(payload, null, 2);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(body),
  });
  res.end(body);
}

function fail(res, status, message) {
  send(res, status, { message });
}

async function readBody(req) {
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  if (!chunks.length) return {};
  try {
    return JSON.parse(Buffer.concat(chunks).toString('utf8'));
  } catch {
    return null; // признак некорректного JSON
  }
}

function currentUser(req) {
  const header = req.headers['authorization'] || '';
  if (!header.startsWith('Bearer ')) return null;
  const payload = verify(header.slice(7));
  if (!payload || payload.type !== 'access') return null;
  return db.users.find((u) => u.id === payload.sub && !u.deletedAt) || null;
}

const ROLE_LEVEL = { reader: 1, librarian: 2, admin: 3 };

function requireRole(res, user, minRole) {
  if (!user) {
    fail(res, 401, 'Требуется аутентификация');
    return false;
  }
  if (ROLE_LEVEL[user.role] < ROLE_LEVEL[minRole]) {
    fail(res, 403, `Операция доступна начиная с роли «${minRole}»`);
    return false;
  }
  return true;
}

const COLLECTIONS = ['books', 'authors', 'genres', 'publishers', 'readers', 'loans'];

// ─────────────────────────────── маршруты ───────────────────────────────

async function handle(req, res, url) {
  const q = Object.fromEntries(url.searchParams.entries());
  const path = url.pathname.replace(/\/+$/, '') || '/';
  const method = req.method.toUpperCase();
  const user = currentUser(req);

  // Учебные переключатели поведения
  if (q.__fail) {
    return fail(res, Number(q.__fail), 'Ошибка вызвана намеренно параметром __fail');
  }

  // ── служебные ──
  if (path === '/api/__reset' && method === 'POST') {
    seed();
    return send(res, 200, { message: 'Данные восстановлены в исходное состояние' });
  }

  if (path === '/api/__health' && method === 'GET') {
    return send(res, 200, { status: 'ok', time: new Date().toISOString() });
  }

  // ── аутентификация ──
  if (path === '/api/auth/register' && method === 'POST') {
    const body = await readBody(req);
    if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');

    const errors = {};
    const username = String(body.username || '').trim();
    const password = String(body.password || '');
    if (username.length < 3) errors.username = 'Логин не короче трёх символов';
    else if (db.users.find((u) => u.username === username)) errors.username = 'Такой логин уже занят';
    if (password.length < 8) errors.password = 'Пароль не короче восьми символов';
    else if (!/\d/.test(password)) errors.password = 'Пароль должен содержать цифру';
    if (body.email && !/^[\w.+-]+@[\w-]+\.[\w.-]+$/.test(String(body.email)))
      errors.email = 'Некорректный адрес почты';

    if (Object.keys(errors).length) {
      return send(res, 422, { message: 'Ошибка валидации', errors });
    }

    const id = push('users', {
      username,
      passwordHash: hash(password),
      fullName: String(body.fullName || username),
      email: String(body.email || ''),
      role: 'reader',
      readerId: null,
    });
    return send(res, 201, expandUser(db.users.find((u) => u.id === id)));
  }

  if (path === '/api/auth/login' && method === 'POST') {
    const body = await readBody(req);
    if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');

    const found = db.users.find(
      (u) => u.username === String(body.username || '').trim() && !u.deletedAt
    );
    if (!found || found.passwordHash !== hash(String(body.password || ''))) {
      return fail(res, 401, 'Неверный логин или пароль');
    }

    const now = Math.floor(Date.now() / 1000);
    const accessToken = sign({ sub: found.id, role: found.role, type: 'access', exp: now + ACCESS_TTL });
    const refreshToken = sign({ sub: found.id, type: 'refresh', exp: now + REFRESH_TTL });
    db.refreshTokens.add(refreshToken);

    return send(res, 200, {
      accessToken,
      refreshToken,
      expiresIn: ACCESS_TTL,
      user: expandUser(found),
    });
  }

  if (path === '/api/auth/refresh' && method === 'POST') {
    const body = await readBody(req);
    const token = body && body.refreshToken;
    const payload = verify(token);
    if (!payload || payload.type !== 'refresh' || !db.refreshTokens.has(token)) {
      return fail(res, 401, 'Токен обновления недействителен');
    }
    const found = db.users.find((u) => u.id === payload.sub);
    if (!found) return fail(res, 401, 'Пользователь не найден');

    db.refreshTokens.delete(token);
    const now = Math.floor(Date.now() / 1000);
    const accessToken = sign({ sub: found.id, role: found.role, type: 'access', exp: now + ACCESS_TTL });
    const refreshToken = sign({ sub: found.id, type: 'refresh', exp: now + REFRESH_TTL });
    db.refreshTokens.add(refreshToken);

    return send(res, 200, { accessToken, refreshToken, expiresIn: ACCESS_TTL, user: expandUser(found) });
  }

  if (path === '/api/auth/me' && method === 'GET') {
    if (!user) return fail(res, 401, 'Требуется аутентификация');
    return send(res, 200, expandUser(user));
  }

  if (path === '/api/auth/logout' && method === 'POST') {
    const body = await readBody(req);
    if (body && body.refreshToken) db.refreshTokens.delete(body.refreshToken);
    return send(res, 204);
  }

  // ── управление пользователями (только admin) ──
  if (path === '/api/users' && method === 'GET') {
    if (!requireRole(res, user, 'admin')) return;
    const rows = applySort(db.users.filter((u) => !u.deletedAt), q.sort);
    const page = paginate(rows, q);
    return send(res, 200, { ...page, items: page.items.map(expandUser) });
  }

  // ── расширения для ПР5 ──
  let roleMatch = path.match(/^\/api\/users\/(\d+)\/role$/);
  if (roleMatch && method === 'PATCH') {
    if (!requireRole(res, user, 'admin')) return;
    const target = db.users.find((u) => u.id === Number(roleMatch[1]) && !u.deletedAt);
    if (!target) return fail(res, 404, 'Пользователь не найден');

    const body = await readBody(req);
    if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');
    const role = String(body.role || '');
    if (!['reader', 'librarian', 'admin'].includes(role)) {
      return send(res, 422, {
        message: 'Ошибка валидации',
        errors: { role: 'Допустимые роли: reader, librarian, admin' },
      });
    }
    target.role = role;
    return send(res, 200, expandUser(target));
  }

  if (path === '/api/admin/stats' && method === 'GET') {
    if (!requireRole(res, user, 'admin')) return;
    const now = new Date();
    const active = db.loans.filter((l) => !l.deletedAt && !l.returnedAt);
    const overdue = active.filter((l) => new Date(l.dueAt) < now);
    return send(res, 200, {
      users: db.users.filter((u) => !u.deletedAt).length,
      books: db.books.filter((b) => !b.deletedAt).length,
      readers: db.readers.filter((r) => !r.deletedAt).length,
      activeLoans: active.length,
      overdueLoans: overdue.length,
    });
  }

  // ── специальные операции с выдачами ──
  if (path === '/api/loans' && method === 'POST') {
    if (!requireRole(res, user, 'librarian')) return;
    const body = await readBody(req);
    if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');

    const errors = {};
    const reader = db.readers.find((r) => r.id === Number(body.readerId) && !r.deletedAt);
    const book = db.books.find((b) => b.id === Number(body.bookId) && !b.deletedAt);
    if (!reader) errors.readerId = 'Читатель не найден';
    if (!book) errors.bookId = 'Книга не найдена';
    const days = Number(body.days || 14);
    if (!Number.isInteger(days) || days < 1 || days > 90) errors.days = 'Срок от 1 до 90 дней';
    if (Object.keys(errors).length) return send(res, 422, { message: 'Ошибка валидации', errors });

    if (book.copiesAvailable < 1) {
      return fail(res, 409, 'Нет свободных экземпляров этой книги');
    }

    const issuedAt = new Date();
    const dueAt = new Date(issuedAt.getTime() + days * 86400000);
    const id = push('loans', {
      readerId: reader.id,
      bookId: book.id,
      issuedAt: issuedAt.toISOString(),
      dueAt: dueAt.toISOString(),
      returnedAt: null,
    });
    book.copiesAvailable -= 1;
    return send(res, 201, expandLoan(db.loans.find((l) => l.id === id)));
  }

  let m = path.match(/^\/api\/loans\/(\d+)\/return$/);
  if (m && method === 'POST') {
    if (!requireRole(res, user, 'librarian')) return;
    const loan = db.loans.find((l) => l.id === Number(m[1]) && !l.deletedAt);
    if (!loan) return fail(res, 404, 'Выдача не найдена');
    if (loan.returnedAt) return fail(res, 409, 'Выдача уже закрыта');

    loan.returnedAt = new Date().toISOString();
    const book = db.books.find((b) => b.id === loan.bookId);
    if (book) book.copiesAvailable = Math.min(book.copiesTotal, book.copiesAvailable + 1);
    return send(res, 200, expandLoan(loan));
  }

  m = path.match(/^\/api\/loans\/(\d+)\/extend$/);
  if (m && method === 'POST') {
    if (!user) return fail(res, 401, 'Требуется аутентификация');
    const loan = db.loans.find((l) => l.id === Number(m[1]) && !l.deletedAt);
    if (!loan) return fail(res, 404, 'Выдача не найдена');
    if (loan.returnedAt) return fail(res, 409, 'Закрытую выдачу продлить нельзя');

    if (user.role === 'reader' && loan.readerId !== user.readerId) {
      return fail(res, 403, 'Читатель может продлевать только собственные выдачи');
    }

    const body = await readBody(req);
    const days = Number((body && body.days) || 7);
    if (!Number.isInteger(days) || days < 1 || days > 30) {
      return send(res, 422, {
        message: 'Ошибка валидации',
        errors: { days: 'Продление от 1 до 30 дней' },
      });
    }

    const base = new Date(loan.dueAt);
    loan.dueAt = new Date(base.getTime() + days * 86400000).toISOString();
    return send(res, 200, expandLoan(loan));
  }

  // ── единообразный CRUD ──
  m = path.match(/^\/api\/([a-z]+)(?:\/(\d+))?(?:\/(restore))?$/);
  const bulk = path.match(/^\/api\/([a-z]+)\/bulk-delete$/);

  if (bulk && method === 'POST') {
    const collection = bulk[1];
    if (!COLLECTIONS.includes(collection)) return fail(res, 404, 'Ресурс не найден');
    if (!requireRole(res, user, 'librarian')) return;

    const body = await readBody(req);
    const ids = Array.isArray(body && body.ids) ? body.ids.map(Number) : [];
    if (!ids.length) return send(res, 422, { message: 'Ошибка валидации', errors: { ids: 'Передайте непустой список идентификаторов' } });

    let deleted = 0;
    for (const row of db[collection]) {
      if (ids.includes(row.id) && !row.deletedAt) {
        row.deletedAt = new Date().toISOString();
        deleted += 1;
      }
    }
    return send(res, 200, { deleted });
  }

  if (m) {
    const collection = m[1];
    const id = m[2] ? Number(m[2]) : null;
    const action = m[3] || null;

    if (!COLLECTIONS.includes(collection)) return fail(res, 404, 'Ресурс не найден');
    const expand = EXPANDERS[collection];

    // восстановление
    if (action === 'restore' && method === 'POST') {
      if (!requireRole(res, user, 'admin')) return;
      const row = db[collection].find((x) => x.id === id);
      if (!row) return fail(res, 404, 'Объект не найден');
      row.deletedAt = null;
      return send(res, 200, expand(row));
    }

    // список
    if (id === null && method === 'GET') {
      let rows = db[collection];
      if (q.includeDeleted !== 'true') rows = rows.filter((x) => !x.deletedAt);

      // читатель видит только свои выдачи
      if (collection === 'loans' && user && user.role === 'reader') {
        rows = rows.filter((l) => l.readerId === user.readerId);
      }

      rows = applyFilters(collection, rows, q);
      rows = applySort(rows, q.sort);
      const page = paginate(rows, q);
      return send(res, 200, { ...page, items: page.items.map(expand) });
    }

    // одна запись
    if (id !== null && method === 'GET') {
      const row = db[collection].find((x) => x.id === id && (q.includeDeleted === 'true' || !x.deletedAt));
      if (!row) return fail(res, 404, 'Объект не найден');
      return send(res, 200, expand(row));
    }

    // создание
    if (id === null && method === 'POST') {
      if (!requireRole(res, user, 'librarian')) return;
      const body = await readBody(req);
      if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');

      const errors = validate(collection, body);
      if (Object.keys(errors).length) return send(res, 422, { message: 'Ошибка валидации', errors });

      const data = normalize(collection, body);
      const newId = push(collection, data);
      const row = db[collection].find((x) => x.id === newId);
      if (collection === 'books') row.copiesAvailable = row.copiesTotal;
      return send(res, 201, expand(row));
    }

    // изменение
    if (id !== null && (method === 'PUT' || method === 'PATCH')) {
      if (!requireRole(res, user, 'librarian')) return;
      const row = db[collection].find((x) => x.id === id && !x.deletedAt);
      if (!row) return fail(res, 404, 'Объект не найден');

      const body = await readBody(req);
      if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');

      const merged = method === 'PATCH' ? { ...row, ...body } : body;
      const errors = validate(collection, merged, id);
      if (Object.keys(errors).length) return send(res, 422, { message: 'Ошибка валидации', errors });

      Object.assign(row, normalize(collection, merged));
      if (collection === 'books') {
        const inUse = db.loans.filter((l) => l.bookId === id && !l.returnedAt && !l.deletedAt).length;
        row.copiesAvailable = Math.max(0, row.copiesTotal - inUse);
      }
      return send(res, 200, expand(row));
    }

    // удаление
    if (id !== null && method === 'DELETE') {
      const hard = q.hard === 'true';
      if (!requireRole(res, user, hard ? 'admin' : 'librarian')) return;

      const index = db[collection].findIndex((x) => x.id === id);
      if (index === -1) return fail(res, 404, 'Объект не найден');

      if (hard) {
        if (collection === 'books') {
          const active = db.loans.some((l) => l.bookId === id && !l.returnedAt && !l.deletedAt);
          if (active) return fail(res, 409, 'Книга выдана и не может быть удалена физически');
        }
        if (collection === 'readers') {
          const active = db.loans.some((l) => l.readerId === id && !l.returnedAt && !l.deletedAt);
          if (active) return fail(res, 409, 'У читателя есть незакрытые выдачи');
        }
        db[collection].splice(index, 1);
      } else {
        db[collection][index].deletedAt = new Date().toISOString();
      }
      return send(res, 204);
    }
  }

  return fail(res, 404, `Адрес ${method} ${path} не обслуживается`);
}

function normalize(collection, body) {
  const num = (v) => (v == null || v === '' ? null : Number(v));
  const str = (v) => (v == null ? '' : String(v).trim());
  const ids = (v) => (Array.isArray(v) ? v.map(Number).filter((n) => Number.isInteger(n)) : []);

  switch (collection) {
    case 'books':
      return {
        title: str(body.title),
        isbn: str(body.isbn),
        year: num(body.year),
        pages: num(body.pages),
        publisherId: num(body.publisherId),
        authorIds: ids(body.authorIds),
        genreIds: ids(body.genreIds),
        copiesTotal: num(body.copiesTotal) ?? 0,
      };
    case 'authors':
      return { fullName: str(body.fullName), birthYear: num(body.birthYear), country: str(body.country) };
    case 'genres':
      return { name: str(body.name), description: str(body.description) };
    case 'publishers':
      return { name: str(body.name), city: str(body.city), foundedYear: num(body.foundedYear) };
    case 'readers':
      return { fullName: str(body.fullName), email: str(body.email), phone: str(body.phone) };
    default:
      return { ...body };
  }
}

// ─────────────────────────────── запуск ───────────────────────────────

seed();

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);

  // Предварительный запрос браузера. Без этого обработчика
  // на web не заработает ни один запрос с заголовком Authorization.
  if (req.method === 'OPTIONS') {
    cors(res);
    res.writeHead(204);
    return res.end();
  }

  const delay = Number(url.searchParams.get('__delay') || 0);
  if (delay > 0) await new Promise((r) => setTimeout(r, Math.min(delay, 10000)));

  const started = Date.now();
  try {
    await handle(req, res, url);
  } catch (err) {
    console.error(err);
    if (!res.headersSent) fail(res, 500, 'Внутренняя ошибка сервера: ' + err.message);
  }
  console.log(
    `${req.method.padEnd(6)} ${url.pathname}${url.search}  → ${res.statusCode}  ${Date.now() - started} мс`
  );
});

server.listen(PORT, () => {
  console.log('');
  console.log('  Учебное API «Библиотека»');
  console.log(`  Адрес:              http://localhost:${PORT}/api`);
  console.log(`  Разрешённый источник: ${ORIGIN}`);
  console.log(`  Срок жизни токена:  ${ACCESS_TTL} с`);
  console.log('');
  console.log('  Учётные записи:  admin/admin123   librarian/librarian123   reader/reader123');
  console.log('  Сброс данных:    POST /api/__reset');
  console.log('  Задержка ответа: любой запрос с ?__delay=1500');
  console.log('  Ошибка по требованию: любой запрос с ?__fail=500');
  console.log('');
});
