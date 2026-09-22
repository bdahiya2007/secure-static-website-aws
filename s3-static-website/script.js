// Sample product data
const products = [
    {
        id: 1,
        title: "Wireless Bluetooth Headphones",
        price: 79.99,
        category: "electronics",
        rating: 4.5,
        reviews: 1234,
        image: "/images/products/wireless-bluetooth-headphones.jpg"
    },
    {
        id: 2,
        title: "Cotton Casual T-Shirt",
        price: 24.99,
        category: "clothing",
        rating: 4.2,
        reviews: 567,
        image: "/images/products/cotton-casual-tshirt.jpg"
    },
    {
        id: 3,
        title: "JavaScript: The Good Parts",
        price: 29.99,
        category: "books",
        rating: 4.7,
        reviews: 890,
        image: "/images/products/javascript-the-good-parts.jpg"
    },
    {
        id: 4,
        title: "Smart LED Light Bulb",
        price: 15.99,
        category: "home",
        rating: 4.3,
        reviews: 445,
        image: "/images/products/smart-led-light-bulb.jpg"
    },
    {
        id: 5,
        title: "Wireless Gaming Mouse",
        price: 49.99,
        category: "electronics",
        rating: 4.6,
        reviews: 778,
        image: "/images/products/wireless-gaming-mouse.jpg"
    },
    {
        id: 6,
        title: "Denim Jeans",
        price: 59.99,
        category: "clothing",
        rating: 4.1,
        reviews: 334,
        image: "/images/products/denim-jeans.jpg"
    },
    {
        id: 7,
        title: "The Art of Clean Code",
        price: 34.99,
        category: "books",
        rating: 4.8,
        reviews: 1122,
        image: "/images/products/the-art-of-clean-code.jpg"
    },
    {
        id: 8,
        title: "Ceramic Coffee Mug Set",
        price: 22.99,
        category: "home",
        rating: 4.4,
        reviews: 267,
        image: "/images/products/ceramic-coffee-mug-set.jpg"
    },
    {
        id: 9,
        title: "4K Webcam",
        price: 89.99,
        category: "electronics",
        rating: 4.5,
        reviews: 543,
        image: "/images/products/4k-webcam.jpg"
    },
    {
        id: 10,
        title: "Running Shoes",
        price: 79.99,
        category: "sports",
        rating: 4.3,
        reviews: 689,
        image: "/images/products/running-shoes.jpg"
    },
    {
        id: 11,
        title: "Yoga Mat",
        price: 29.99,
        category: "sports",
        rating: 4.6,
        reviews: 412,
        image: "/images/products/yoga-mat.jpg"
    },
    {
        id: 12,
        title: "Stainless Steel Water Bottle",
        price: 19.99,
        category: "sports",
        rating: 4.4,
        reviews: 356,
        image: "/images/products/stainless-steel-water-bottle.jpg"
    }
];

// Shopping cart
let cart = [];

// Current displayed products
let currentProducts = [...products];

// Initialize the page
document.addEventListener('DOMContentLoaded', function() {
    displayProducts(products);
    updateCartCount();

    // Handle search on Enter key
    document.getElementById('searchInput').addEventListener('keypress', function(e) {
        if (e.key === 'Enter') {
            searchProducts();
        }
    });

    // Close cart when clicking outside
    document.addEventListener('click', function(e) {
        const cartSidebar = document.getElementById('cartSidebar');
        const cartButton = document.querySelector('.cart');

        if (!cartSidebar.contains(e.target) && !cartButton.contains(e.target) && cartSidebar.classList.contains('open')) {
            toggleCart();
        }
    });

    // Close cart on Escape
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape' && document.getElementById('cartSidebar').classList.contains('open')) {
            toggleCart();
        }
    });
});

// Display products in the grid
function displayProducts(productsToShow) {
    const productsGrid = document.getElementById('productsGrid');
    
    if (productsToShow.length === 0) {
        productsGrid.innerHTML = '<p style="grid-column: 1/-1; text-align: center; color: #666; padding: 40px;">No products found matching your search.</p>';
        return;
    }
    
    productsGrid.innerHTML = productsToShow.map(product => `
        <div class="product-card">
            <div class="product-image">
                <img src="${product.image}" alt="${product.title}" loading="lazy">
            </div>
            <h3 class="product-title">${product.title}</h3>
            <div class="product-rating">
                <span class="stars">${generateStars(product.rating)}</span>
                <span class="rating-count">(${product.reviews})</span>
            </div>
            <div class="product-price">$${product.price.toFixed(2)}</div>
            <button class="add-to-cart" onclick="addToCart(${product.id})">Add to Cart</button>
        </div>
    `).join('');
}

// Generate star rating display
function generateStars(rating) {
    // Round to the nearest half star first, so e.g. 4.2 -> 4 full stars
    // (no half) and 4.8 -> 5 full stars, instead of every non-integer
    // rating showing an identical "4 full + half" display.
    const rounded = Math.round(rating * 2) / 2;
    const fullStars = Math.floor(rounded);
    const hasHalfStar = rounded % 1 !== 0;
    let stars = '';
    
    for (let i = 0; i < fullStars; i++) {
        stars += '★';
    }
    
    if (hasHalfStar) {
        stars += '☆';
    }
    
    return stars;
}

// Search products
function searchProducts() {
    const searchTerm = document.getElementById('searchInput').value.toLowerCase();
    const category = document.querySelector('.search-category').value;
    
    let filteredProducts = products;
    
    // Filter by category if not "all"
    if (category !== 'all') {
        filteredProducts = filteredProducts.filter(product => product.category === category);
    }
    
    // Filter by search term
    if (searchTerm) {
        filteredProducts = filteredProducts.filter(product => 
            product.title.toLowerCase().includes(searchTerm) ||
            product.category.toLowerCase().includes(searchTerm)
        );
    }
    
    currentProducts = filteredProducts;
    displayProducts(filteredProducts);
    
    // Update section title
    const sectionTitle = document.getElementById('sectionTitle');
    if (searchTerm) {
        sectionTitle.textContent = `Search results for "${searchTerm}"`;
    } else if (category !== 'all') {
        sectionTitle.textContent = `${category.charAt(0).toUpperCase() + category.slice(1)} Products`;
    } else {
        sectionTitle.textContent = 'All Products';
    }
}

// Filter products by category
function filterProducts(category) {
    let filteredProducts = products;
    
    if (category !== 'all') {
        filteredProducts = products.filter(product => product.category === category);
    }
    
    currentProducts = filteredProducts;
    displayProducts(filteredProducts);
    
    // Update section title
    const sectionTitle = document.getElementById('sectionTitle');
    if (category === 'all') {
        sectionTitle.textContent = 'All Products';
    } else {
        sectionTitle.textContent = `${category.charAt(0).toUpperCase() + category.slice(1)} Products`;
    }
    
    // Clear search input
    document.getElementById('searchInput').value = '';
    document.querySelector('.search-category').value = 'all';
}

// Add product to cart
function addToCart(productId) {
    const product = products.find(p => p.id === productId);
    if (!product) {
        return;
    }

    const existingItem = cart.find(item => item.id === productId);

    if (existingItem) {
        existingItem.quantity += 1;
    } else {
        cart.push({
            ...product,
            quantity: 1
        });
    }
    
    updateCartCount();
    updateCartDisplay();
    
    // Show brief feedback
    showAddToCartFeedback();
}

// Show add to cart feedback
function showAddToCartFeedback() {
    const cartElement = document.querySelector('.cart');
    cartElement.style.transform = 'scale(1.1)';
    setTimeout(() => {
        cartElement.style.transform = 'scale(1)';
    }, 200);
}

// Update cart count in header
function updateCartCount() {
    const cartCount = document.getElementById('cartCount');
    const totalItems = cart.reduce((sum, item) => sum + item.quantity, 0);
    cartCount.textContent = totalItems;
}

// Toggle cart sidebar
function toggleCart() {
    const cartSidebar = document.getElementById('cartSidebar');
    const overlay = document.getElementById('overlay');
    
    cartSidebar.classList.toggle('open');
    overlay.classList.toggle('active');
    
    if (cartSidebar.classList.contains('open')) {
        updateCartDisplay();
    }
}

// Update cart display
function updateCartDisplay() {
    const cartItems = document.getElementById('cartItems');
    const cartTotal = document.getElementById('cartTotal');
    
    if (cart.length === 0) {
        cartItems.innerHTML = '<div class="empty-cart">Your cart is empty</div>';
        cartTotal.textContent = '0.00';
        return;
    }
    
    cartItems.innerHTML = cart.map(item => `
        <div class="cart-item">
            <div class="cart-item-image">
                <img src="${item.image}" alt="${item.title}">
            </div>
            <div class="cart-item-details">
                <div class="cart-item-title">${item.title}</div>
                <div class="cart-item-price">$${item.price.toFixed(2)}</div>
                <div class="quantity-controls">
                    <button class="quantity-btn" onclick="updateQuantity(${item.id}, -1)">-</button>
                    <span>${item.quantity}</span>
                    <button class="quantity-btn" onclick="updateQuantity(${item.id}, 1)">+</button>
                    <button class="remove-item" onclick="removeFromCart(${item.id})">Remove</button>
                </div>
            </div>
        </div>
    `).join('');
    
    const total = cart.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    cartTotal.textContent = total.toFixed(2);
}

// Update item quantity in cart
function updateQuantity(productId, change) {
    const item = cart.find(item => item.id === productId);
    
    if (item) {
        item.quantity += change;
        
        if (item.quantity <= 0) {
            removeFromCart(productId);
        } else {
            updateCartCount();
            updateCartDisplay();
        }
    }
}

// Remove item from cart
function removeFromCart(productId) {
    cart = cart.filter(item => item.id !== productId);
    updateCartCount();
    updateCartDisplay();
}

// Checkout function
function checkout() {
    if (cart.length === 0) {
        alert('Your cart is empty!');
        return;
    }
    
    const total = cart.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    const itemCount = cart.reduce((sum, item) => sum + item.quantity, 0);
    
    alert(`Thank you for your purchase!\n\nItems: ${itemCount}\nTotal: $${total.toFixed(2)}\n\nYour order has been placed successfully!`);
    
    // Clear cart after checkout
    cart = [];
    updateCartCount();
    updateCartDisplay();
    toggleCart();
}

