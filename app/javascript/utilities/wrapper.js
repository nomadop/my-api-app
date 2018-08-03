import NProgress from 'nprogress';

export const wrap_fetch = (fetch_fn, singleton = true) => {
  return function (...args) {
    if (singleton && this.fetching) {
      return;
    }

    if (singleton) {
      this.fetching = true;
      NProgress.start();
    }

    const show_message = (type, message) => {
      return this.on_message ? this.on_message({ type, message }) : this.$emit('message', { type, message });
    };
    fetch_fn.bind(this)(...args)
      .then(response => {
        if (singleton) {
          this.fetching = false;
          NProgress.done();
        }
        response && response.status === 500 ?
          show_message('error', response.statusText) :
          show_message('info', 'success');
      })
      .catch(error => {
        if (singleton) {
          this.fetching = false;
          NProgress.done();
        }
        console.log(error);
        show_message('error', error);
      });
  };
};

