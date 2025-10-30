FROM cgr.dev/chainguard/nginx

# Copy app code
COPY 2two2.me/nginx/nginx.conf /etc/nginx/nginx.conf

# Expose ports
EXPOSE 80 443

# Run the app
CMD ["nginx", "-g", "daemon off;" ]

