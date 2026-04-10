# 🛋️ VisionFurnish — Backend API

Premium furniture ecommerce REST API built with **Node.js**, **Express**, and **MySQL**.

---

## ⚡ Quick Start

### Prerequisites

- [Node.js](https://nodejs.org/) v18+
- [MySQL](https://www.mysql.com/) 8.0+

### 1. Install Dependencies

```bash
cd vf
npm install
```

### 2. Setup Database

Import the schema into MySQL:

```bash
mysql -u root -p < schema.sql
```

Or open **MySQL Workbench** and run the contents of `schema.sql`.

### 3. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set your MySQL credentials:

```env
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=visionfurnish
JWT_SECRET=change_this_to_a_random_secret
```

### 4. Start the Server

```bash
# Development (with auto-reload)
npm run dev

# Production
npm start
```

The API will be available at `http://localhost:5000`.

---

## 📁 Project Structure

```
vf/
├── server.js                      # Entry point
├── package.json
├── schema.sql                     # MySQL DDL (8 tables)
├── .env.example
└── src/
    ├── config/
    │   └── db.js                  # MySQL connection pool
    ├── middleware/
    │   ├── auth.js                # JWT + role guard
    │   ├── validate.js            # Request validation
    │   └── errorHandler.js        # Global error handler
    ├── utils/
    │   ├── response.js            # JSON response helper
    │   └── otp.js                 # OTP generator
    ├── controllers/
    │   ├── authController.js
    │   ├── productController.js
    │   ├── categoryController.js
    │   ├── cartController.js
    │   ├── orderController.js
    │   ├── wishlistController.js
    │   └── reviewController.js
    └── routes/
        ├── auth.js
        ├── products.js
        ├── categories.js
        ├── cart.js
        ├── orders.js
        ├── wishlist.js
        └── reviews.js
```

---

## 🔗 API Endpoints

### Health Check

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/health` | Server status |

### Auth (`/api/auth`)

| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| POST | `/register` | Public | Create account |
| POST | `/login` | Public | Login & get token |
| POST | `/forgot-password` | Public | Request OTP |
| POST | `/verify-otp` | Public | Verify OTP |
| POST | `/reset-password` | Public | Reset password |
| GET | `/profile` | 🔒 User | Get profile |

### Products (`/api/products`)

| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| GET | `/` | Public | List all (paginated, filterable) |
| GET | `/search?q=` | Public | Search products |
| GET | `/:id` | Public | Product details |
| POST | `/` | 🔒 Admin | Create product |
| PUT | `/:id` | 🔒 Admin | Update product |
| DELETE | `/:id` | 🔒 Admin | Delete product |

**Query Params:** `page`, `limit`, `sort` (price/created_at/name), `order` (asc/desc), `category_id`, `min_price`, `max_price`, `is_featured`

### Categories (`/api/categories`)

| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| GET | `/` | Public | List all with product count |
| GET | `/:id` | Public | Category + subcategories |
| POST | `/` | 🔒 Admin | Create category |
| PUT | `/:id` | 🔒 Admin | Update category |
| DELETE | `/:id` | 🔒 Admin | Delete category |

### Cart (`/api/cart`)

| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| GET | `/` | 🔒 User | View cart with totals |
| POST | `/` | 🔒 User | Add to cart |
| PUT | `/:id` | 🔒 User | Update quantity |
| DELETE | `/:id` | 🔒 User | Remove item |
| DELETE | `/` | 🔒 User | Clear cart |

### Orders (`/api/orders`)

| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| POST | `/` | 🔒 User | Place order (from cart) |
| GET | `/` | 🔒 User | My orders |
| GET | `/:id` | 🔒 User | Order details |
| GET | `/all` | 🔒 Admin | All orders |
| PUT | `/:id/status` | 🔒 Admin | Update order status |

### Wishlist (`/api/wishlist`)

| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| GET | `/` | 🔒 User | View wishlist |
| POST | `/` | 🔒 User | Add product |
| DELETE | `/:productId` | 🔒 User | Remove product |

### Reviews (`/api/reviews`)

| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| GET | `/product/:productId` | Public | Product reviews |
| POST | `/` | 🔒 User | Submit review |
| PUT | `/:id` | 🔒 User | Update own review |
| DELETE | `/:id` | 🔒 User/Admin | Delete review |

---

## 🔐 Authentication

Include the JWT token in the `Authorization` header:

```
Authorization: Bearer <your_jwt_token>
```

---

## 📦 Database

The schema creates **8 tables** with full relational integrity:

- `users` — accounts with role-based access
- `categories` — hierarchical (self-referencing `parent_id`)
- `products` — full-text search, JSON image arrays
- `reviews` — one per user per product
- `cart` — per-user with stock validation
- `wishlist` — per-user, duplicate prevention
- `orders` — transactional with status tracking
- `order_items` — line items with price snapshot

---

## 📝 License

ISC
