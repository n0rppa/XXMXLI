// Form validation functionality
function validateForm(formElement) {
    const inputs = formElement.querySelectorAll('input, textarea');
    let isValid = true;

    inputs.forEach(input => {
        // Reset previous error states
        input.classList.remove('error');
        const errorElement = input.nextElementSibling;
        if (errorElement && errorElement.classList.contains('error-message')) {
            errorElement.remove();
        }

        // Validate required fields
        if (input.hasAttribute('required') && !input.value.trim()) {
            showError(input, 'Tämä kenttä on pakollinen');
            isValid = false;
        }

        // Validate email format
        if (input.type === 'email' && input.value) {
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            if (!emailRegex.test(input.value)) {
                showError(input, 'Syötä kelvollinen sähköpostiosoite');
                isValid = false;
            }
        }

        // Validate minimum length
        if (input.hasAttribute('minlength')) {
            const minLength = parseInt(input.getAttribute('minlength'));
            if (input.value.length < minLength) {
                showError(input, `Vähimmäispituus on ${minLength} merkkiä`);
                isValid = false;
            }
        }
    });

    return isValid;
}

function showError(input, message) {
    input.classList.add('error');
    const errorDiv = document.createElement('div');
    errorDiv.className = 'error-message';
    errorDiv.setAttribute('aria-live', 'polite');
    errorDiv.textContent = message;
    input.parentNode.insertBefore(errorDiv, input.nextSibling);
}

// Add form validation to all forms
document.addEventListener('DOMContentLoaded', () => {
    const forms = document.querySelectorAll('form');
    forms.forEach(form => {
        form.addEventListener('submit', (e) => {
            if (!validateForm(form)) {
                e.preventDefault();
            }
        });
    });
});
