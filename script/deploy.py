from src import ERC1967, counter_one, counter_two
import boa
import warnings


def deploy():
    implementation = counter_one.deploy()
    proxy = ERC1967.deploy(implementation, boa.env.eoa)

    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        proxy_with_abi = counter_one.at(proxy.address)
    proxy_with_abi.set_number(77)

    print(f"Starting number: {proxy_with_abi.number()}")
    print(f"Starting version: {proxy_with_abi.version()}")

    # Let's Upgrade!
    implementation_two = counter_two.deploy()
    proxy.upgrade_to(implementation_two)

    print(f"The same number: {proxy_with_abi.number()}")
    print(f"A new version: {proxy_with_abi.version()}")

    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        proxy_with_abi = counter_two.at(proxy.address)
    proxy_with_abi.decrement()
    print(f"Decrement number: {proxy_with_abi.number()}")


def moccasin_main():
    return deploy()
